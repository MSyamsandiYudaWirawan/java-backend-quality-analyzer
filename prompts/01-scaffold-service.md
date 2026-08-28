# Prompt Template: Scaffold a New Service

> Use this at kickoff to spin up a service skeleton matching our proven baseline structure.
> This template reflects the exact stack we validated: Spring MVC + JPA + PostgreSQL + JMH + k6.

---

## Paste this into your AI console

```
Scaffold a Spring Boot service with the following exact stack and folder layout.

### Project Layout

```
service/
├── pom.xml
├── Dockerfile
├── src/
│   ├── main/
│   │   ├── java/com/[YOUR_DOMAIN]/[YOUR_APP]/
│   │   │   ├── [YourApp]Application.java
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
│   │       └── application-docker.yaml       (Docker benchmark profile)
│   └── test/
│       └── java/com/[YOUR_DOMAIN]/[YOUR_APP]/
│           └── benchmark/
│               ├── BenchmarkRunner.java
│               └── (JMH benchmarks added later)
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
        <!-- Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webmvc</artifactId>
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

        <!-- Data -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- JMH (test scope) -->
        <dependency>
            <groupId>org.openjdk.jmh</groupId>
            <artifactId>jmh-core</artifactId>
            <version>1.37</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.openjdk.jmh</groupId>
            <artifactId>jmh-generator-annprocess</artifactId>
            <version>1.37</version>
            <scope>test</scope>
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
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.5.0</version>
                <configuration>
                    <classpathScope>test</classpathScope>
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
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: username
    password: password
    driver-class-name: org.postgresql.Driver
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: create-drop
    open-in-view: false
```

### application-docker.yml (Docker benchmark profile)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://postgres:5432/mydb
    username: username
    password: password
    driver-class-name: org.postgresql.Driver
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

### Requirements

1. **Spring MVC** (synchronous, NOT WebFlux) — we measured this stack.
2. **Actuator health endpoint** at `/actuator/health` — the orchestrator polls this.
3. **One domain entity** with:
   - JPA `@Entity` + `@Id @GeneratedValue(strategy = GenerationType.UUID)`
   - Repository extends `JpaRepository<ENTITY, UUID>`
   - Service interface + `@Service` implementation
   - REST controller with `@RestController` + `@RequestMapping("/api/v1/[resource]")`
   - POST creates, GET by UUID reads
   - Lombok `@Builder` on request/response DTOs
4. **Validation** on request DTOs (`@NotBlank`, `@NotNull`, etc.)
5. **Error handling:** `RuntimeException` → 404 for not-found; validation errors → 400.
6. **BenchmarkRunner.java** in `src/test/java/.../benchmark/`:
   ```java
   package ...;
   import org.openjdk.jmh.Main;
   public class BenchmarkRunner {
       public static void main(String[] args) throws Exception { Main.main(args); }
   }
   ```
7. **Folder structure:** Use `service/` for the Maven project, NOT at repo root.

### Do NOT include
- Custom test framework abstractions
- Prometheus/Grafana setup
- Redis/Kafka unless the problem explicitly requires them

### Output
Full file contents for every file. No placeholders like "...". Replace [brackets] with the actual domain names I provide.
```

---

## How to use at kickoff

1. Read the problem PDF. Identify the domain (e.g., `order`, `auction`, `payment`).
2. Copy the prompt block above.
3. Replace `[YOUR_DOMAIN]`, `[YOUR_APP]`, `[Entity]`, `[resource]` with actual names.
4. Paste into AI console.
5. **Save the trajectory** immediately after the response.
6. Run `mvn test-compile` to verify it builds.
7. Run `docker compose up -d` to start Postgres.
8. Run `./run-experiment.sh baseline` (native) or `./run-experiment.sh baseline --docker` (isolated) to verify end-to-end.
