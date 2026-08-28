# Prompt Template: Scaffold a Reactive Service (WebFlux + R2DBC + Redis)

> Use this at kickoff to spin up a reactive service skeleton matching our proven baseline structure.
> This template reflects the exact stack we validated: Spring WebFlux + R2DBC + PostgreSQL + Redis + k6.
>
> **If the problem does not require caching, tell the AI: "Skip Redis — no caching layer needed."**

---

## Paste this into your AI console

```
Scaffold a Spring Boot reactive service with the following exact stack and folder layout.

### Project Layout

```
service/
├── pom.xml
├── Dockerfile
├── src/
│   ├── main/
│   │   ├── java/com/[YOUR_DOMAIN]/[YOUR_APP]/
│   │   │   ├── [YourApp]Application.java
│   │   │   ├── config/
│   │   │   │   └── RedisConfig.java          (skip if no Redis)
│   │   │   ├── redis/
│   │   │   │   └── RedisService.java         (skip if no Redis)
│   │   │   ├── [Domain]Controller.java
│   │   │   └── [domain]/
│   │   │       ├── [Entity].java
│   │   │       ├── [Entity]Repository.java
│   │   │       ├── [Entity]Service.java
│   │   │       ├── impl/[Entity]ServiceImpl.java
│   │   │       ├── request/Create[Entity]Request.java
│   │   │       └── response/Get[Entity]Response.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-docker.yaml       (Docker benchmark profile)
│   │       └── schema.sql
│   └── test/
│       └── java/com/[YOUR_DOMAIN]/[YOUR_APP]/
benchmarks/
├── k6-baseline.js
├── k6-advanced.js
├── k6-report.js
└── orchestrate.js
evidence/
├── experiments/
│   ├── README.md
│   └── h1-*.md (added per experiment)
└── (JFR + k6 JSON outputs generated at runtime)
tests/
├── unit/
├── integration/
└── chaos/
```

### pom.xml (exact dependencies)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.1.1</version>
        <relativePath/>
    </parent>

    <groupId>com.[YOUR_DOMAIN]</groupId>
    <artifactId>[YOUR_APP]</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>
        <!-- WebFlux (reactive, NOT MVC) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>

        <!-- Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- Actuator (health endpoint for orchestrate.js) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <!-- R2DBC + PostgreSQL driver -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-r2dbc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>r2dbc-postgresql</artifactId>
        </dependency>

        <!-- Redis (reactive) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### application.yml (exact config)

```yaml
spring:
  application:
    name: [YOUR_APP]
  r2dbc:
    url: r2dbc:postgresql://localhost:5432/mydb
    username: username
    password: password
  data:
    redis:
      host: localhost
      port: 6379
  sql:
    init:
      mode: always
```

### application-docker.yml (Docker benchmark profile)

```yaml
spring:
  r2dbc:
    url: r2dbc:postgresql://postgres:5432/mydb
    username: username
    password: password
  data:
    redis:
      host: redis
      port: 6379
```

### Dockerfile (benchmark runtime)

```dockerfile
# ============================================================================
# Service Dockerfile — Benchmark Runtime
# ============================================================================
# NOTE: We use eclipse-temurin:21-jre-jammy (glibc) instead of -alpine (musl).
# musl libc has a broken sendfile() implementation that corrupts JFR chunk
# headers, producing unreadable recordings.
# ============================================================================

FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && apt-get install -y --no-install-recommends wget curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /jfr-repo && chmod 777 /jfr-repo

COPY target/*.jar app.jar

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
```

### schema.sql (exact)

```sql
CREATE TABLE IF NOT EXISTS [entity]
(
    id        UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    [field1]  VARCHAR(255) NOT NULL,
    [field2]  [TYPE] NOT NULL
);
```

### RedisConfig.java (production-ready, Jackson 3, non-deprecated)

```java
package com.[YOUR_DOMAIN].[YOUR_APP].config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.GenericJacksonJsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.RedisSerializer;
import tools.jackson.databind.jsontype.BasicPolymorphicTypeValidator;

@Configuration
public class RedisConfig {

    @Bean
    public ReactiveRedisTemplate<String, Object> reactiveRedisTemplate(ReactiveRedisConnectionFactory factory) {
        GenericJacksonJsonRedisSerializer valueSerializer = GenericJacksonJsonRedisSerializer.builder()
                .enableDefaultTyping(BasicPolymorphicTypeValidator.builder()
                        .allowIfBaseType(Object.class)
                        .build())
                .build();

        RedisSerializationContext<String, Object> context =
                RedisSerializationContext.<String, Object>newSerializationContext(RedisSerializer.string())
                        .value(RedisSerializationContext.SerializationPair.fromSerializer(valueSerializer))
                        .build();

        return new ReactiveRedisTemplate<>(factory, context);
    }
}
```

### RedisService.java (cache-aside pattern)

```java
package com.[YOUR_DOMAIN].[YOUR_APP].redis;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.Duration;

@RequiredArgsConstructor
@Service
public class RedisService {

    private final ReactiveRedisTemplate<String, Object> reactiveRedisTemplate;
    private static final Duration DEFAULT_TTL = Duration.ofHours(24);

    public Mono<Boolean> isDuplicate(String key) {
        return reactiveRedisTemplate.hasKey(key);
    }

    public Mono<[Entity]> get[Entity](String key) {
        return reactiveRedisTemplate.opsForValue()
                .get(key)
                .cast([Entity].class);
    }

    public Mono<Boolean> store(String key, [Entity] value) {
        return reactiveRedisTemplate.opsForValue()
                .set(key, value, DEFAULT_TTL);
    }

    public Mono<Boolean> storeIfAbsent(String key, [Entity] value) {
        return reactiveRedisTemplate.opsForValue()
                .setIfAbsent(key, value, DEFAULT_TTL);
    }
}
```

### Requirements

1. **Spring WebFlux** (reactive, NOT MVC) — we validated this stack.
2. **R2DBC** (NOT JPA) — repository extends `R2dbcRepository<ENTITY, UUID>`.
3. **Actuator health endpoint** at `/actuator/health` — the orchestrator polls this.
4. **One domain entity** with:
   - `@Table(name = "[entity]")` + `@Id private UUID id;`
   - Repository extends `R2dbcRepository<ENTITY, UUID>`
   - Service interface + `@Service` implementation returning `Mono<T>`
   - REST controller with `@RestController` + `@RequestMapping("/api/v1/[resource]")`
   - POST creates (returns `Mono<ResponseEntity<ENTITY>>` with `201 CREATED`)
   - GET by UUID reads (returns `Mono<ResponseEntity<Get[Entity]Response>>`)
   - Lombok `@Builder` on entity + request/response DTOs
5. **Validation** on request DTOs (`@NotBlank`, `@NotNull`, `@DecimalMin`, etc.)
6. **Error handling:** `RuntimeException` → 404 for not-found; validation errors → 400.
7. **Cache-aside pattern** (if Redis is enabled):
   - `findById`: check Redis → miss → query DB → store in Redis → return response
   - `save`: persist to DB → store in Redis → return entity
   - Use `storeIfAbsent` to avoid overwriting fresher cache entries on concurrent reads
8. **Folder structure:** Use `service/` for the Maven project, NOT at repo root.

### Skip Redis

If the problem does not require caching, tell the AI: **"Skip Redis — remove RedisConfig, RedisService, and redis dependency from pom.xml."**
The service should then read directly from R2DBC repository with no cache layer.

### Do NOT include
- Custom test framework abstractions
- Prometheus/Grafana setup
- Kafka unless the problem explicitly requires it
- JMH benchmarks (we use k6 for load testing reactive services)

### Output
Full file contents for every file. No placeholders like "...". Replace [brackets] with the actual domain names I provide.
```

---

## How to use at kickoff

1. Read the problem PDF. Identify the domain (e.g., `order`, `auction`, `payment`).
2. Copy the prompt block above.
3. Replace `[YOUR_DOMAIN]`, `[YOUR_APP]`, `[Entity]`, `[resource]` with actual names.
4. Decide if caching is needed. If not, add: **"Skip Redis."**
5. Paste into AI console.
6. **Save the trajectory** immediately after the response.
7. Run `./mvnw test-compile` to verify it builds.
8. Run `docker compose up -d` to start Postgres + Redis.
9. Run `./run-experiment.sh baseline` (native) or `./run-experiment.sh baseline --docker` (isolated) to verify end-to-end.
