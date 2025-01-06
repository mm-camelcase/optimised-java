# Java Optimised

Java Optimised is a project aimed at improving the performance of Java/Spring Boot workflows by optimising build times, reducing image sizes, and decreasing memory and CPU footprints. This project demonstrates a series of optimisation techniques across different areas, focusing on both build workflows and runtime performance.

The target test service used in this project is a basic **User Service** application. It is a CRUD API built with Spring Boot and Spring Data JPA, designed to perform typical operations such as creating, reading, updating, and deleting user records. This service provides a realistic baseline for evaluating various optimisation strategies.

[todo- more concise]  
[todo- short descriptioon at start of each section]  
[todo- explain load test, stats tool - jvm metrics not availabale with native builds so stats gathered using docker stats via psrecord]  
[todo- add a list of other areas to optomise]  
[dissad nativeimage]

---

## Table of Contents
- [Java Optimised](#java-optimised)
- [Optimisation Areas](#optimisation-areas)
  - [1. Build Workflow Optimisations](#1-build-workflow-optimisations)
    - [Multi-Stage Builds](#multi-stage-builds)
    - [Gradle & Docker Caching](#gradle--docker-caching)
  - [2. Runtime Performance Optimisations](#2-runtime-performance-optimisations)
    - [Lightweight Runtime Image](#lightweight-runtime-image)
    - [GraalVM Native Image](#graalvm-native-image)
- [Metrics and Comparison](#metrics-and-comparison)
- [How to Run](#how-to-run)
- [Contributing](#contributing)
- [License](#license)
---

## Optimisation Areas

The project focuses on two primary areas of optimisation:

1. **Build Workflow Optimisations**
2. **Runtime Performance Optimisations**

Each optimisation technique is explored in detail, with links to corresponding branches where the implementations can be found.

---

### 1. Build Workflow Optimisations

Efficient build workflows reduce development cycle times and improve deployment efficiency. The following optimisations target build processes:

#### Multi-Stage Builds ([`user-service example`](https://github.com/mm-camelcase/user-service/blob/optomised-v1/Dockerfile))

**Description:** Multi-stage builds split the build and runtime environments into separate Docker layers, reducing the final image size and simplifying deployment processes. By using multi-stage builds, you can exclude unnecessary tools from the final image and reduce security risks.  

Example Dockerfile snippet:
```dockerfile
# Stage 1: Build
FROM maven:3.9.5-eclipse-temurin-17 as builder
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM amazoncorretto:17-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Key Benefits:**

- Smaller image size (see size comparisons between [Single-Stage Builds](#table-1-single-stage-builds-jdk-included) and [Multi-Stage Builds](#table-2-multi-stage-builds-jdk-for-build-stage-jre-for-runtime) below )
- Reduced build times
- Improved security by minimising the attack surface
- Simpler CI/CD Pipelines

---

#### Gradle & Docker Caching ([`user-service example`](https://github.com/mm-camelcase/user-service/blob/optomised-v3/Dockerfile))

**Description:** This technique leverages caching mechanisms for Gradle and Docker layers to avoid redundant build steps and speed up subsequent builds. Caching is essential for large projects, where rebuilding the same layers repeatedly can waste time and resources.

**Description:** This optimisation leverages caching mechanisms for both Gradle dependencies and Docker layers. Gradle caching ensures that previously downloaded dependencies are reused, while Docker layer caching avoids rebuilding unchanged layers, significantly speeding up build times in CI/CD pipelines. Caching is essential for large projects, where rebuilding the same layers repeatedly can waste time and resources.

**Key Benefits:**

- Faster build times by avoiding redundant steps
- Reduced network usage during builds
- Optimised CI/CD pipelines for faster deployments

Example Gradle Cache Workflow:
```yml
...
      # Cache Gradle dependencies
      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            gradle-${{ runner.os }}-
            gradle-
...
```

Example Docker Layer Cache Workflow:
```yml
...
      # Cache Docker layers
      - name: Cache Docker layers
        uses: actions/cache@v4
        with:
          path: /tmp/.buildx-cache
          key: docker-cache-${{ github.ref_name }}-${{ hashFiles('Dockerfile') }}
          restore-keys: |
            docker-cache-${{ github.ref_name }}-
            docker-cache-
...
```

**Results:**

Caching significantly reduced the build and push time for a Java source code change (with no modifications to Gradle dependencies or the Dockerfile).

| Metric          | `no caching` | `caching enabled` |
|-----------------|-----------------|----------------|
| Build Time      | 57 s           | 4s          |
| Push Time       | 28 s            | 2s          |

---

### 2. Runtime Performance Optimisations

Optimising runtime performance can significantly improve application scalability and reduce operational costs. The following techniques focus on runtime improvements:

#### Lightweight Runtime Image ([`user-service example`](https://github.com/mm-camelcase/user-service/blob/optomised-v2/Dockerfile#L21))

**Description:** Using lightweight base images, such as Alpine or Distroless, reduces the final image size and enhances security by limiting the number of installed packages. This can improve application performance and reduce cloud infrastructure costs.

**Key Benefits:**

- Smaller image sizes
- Enhanced security
- Reduced resource consumption

Here are commonly used Java 17 base images for various requirements. Image sizes vary significantly, affecting resource usage and costs, so choosing an optimised image can help lower cloud expenses.

##### Table 1: Single-Stage Builds (JDK Included)

| **Image**                          | **Base OS**      | **Size**   | **Use Case**                    | **Pros**                                            | **Cons**                              |
|------------------------------------|------------------|------------|---------------------------------|----------------------------------------------------|---------------------------------------|
| `eclipse-temurin:17-jdk`           | Debian/Ubuntu    | ~300 MB    | General purpose                 | Well-maintained, widely used, secure               | Larger image size                     |
| `amazoncorretto:17`                | Amazon Linux 2   | ~200 MB    | AWS deployments                 | Optimised for AWS, long-term support by Amazon     | Tied to AWS ecosystem                 |
| `openjdk:17-jdk`                   | Debian/Ubuntu    | ~300 MB    | General purpose                 | Official OpenJDK build, widely compatible          | Larger size compared to other JDKs    |
| `eclipse-temurin:17-jdk-alpine`    | Alpine Linux     | ~80 MB     | Minimal image size              | Very small image, suitable for lightweight apps    | Potential compatibility issues        |
| `ghcr.io/graalvm/graalvm-ce:java17`| Oracle Linux     | ~350 MB    | Native builds and performance   | Supports native compilation with `native-image`    | Larger size and complex native builds |


##### Table 2: Multi-Stage Builds (JDK for Build Stage, JRE for Runtime)

| **Runtime Image**                  | **Base OS**      | **Size**   | **Use Case**                    | **Pros**                                            | **Cons**                              |
|------------------------------------|------------------|------------|---------------------------------|----------------------------------------------------|---------------------------------------|
| `eclipse-temurin:17-jre`           | Debian/Ubuntu    | ~70 MB     | General purpose runtime         | Well-maintained, widely used, secure               | Slightly larger than Alpine-based JRE |
| `amazoncorretto:17-al2-jre`        | Amazon Linux 2   | ~40 MB     | AWS deployments                 | Optimised for AWS, secure                          | AWS-specific                          |
| `eclipse-temurin:17-jre-alpine`    | Alpine Linux     | ~30 MB     | Minimal image size              | Very small, suitable for lightweight apps          | Potential glibc compatibility issues  |
| `cgr.dev/chainguard/jre:17`        | Distroless       | ~50 MB     | Security-focused runtime        | Minimal attack surface, no shell                  | Limited debugging options             |
| `gcr.io/distroless/java17-debian11`| Distroless       | ~50 MB     | Secure production deployments   | Reduced attack surface, no package manager         | No shell or package manager           |
| `ghcr.io/graalvm/graalvm-ce:java17`| Oracle Linux     | ~80 MB     | Native builds                   | Use `native-image` to produce a native executable  | Native builds require more setup      |



---

#### GraalVM Native Image ([`optimised-v4`](https://github.com/yourusername/java-optimized/tree/optimised-v4))

**Description:** GraalVM enables Java applications to be compiled into native executables, resulting in faster startup times and lower memory usage. This is particularly beneficial for serverless environments and microservices where cold start times are critical.

**Key Benefits:**

- Faster startup times
- Reduced resource usage
- Faster startup times.
- Optimised for microservices and serverless functions

**Results:**

| ![Standard Image](results/standard.png) | ![Native Image](results/native.png) |
|--------------------------------------|------------------------------------------|
| **Standard Image**                          | **Native Image**                            | |

---

## Metrics and Comparison

The project tracks and compares the following key metrics across branches:

| Metric          | `optimised-v1` | `optimised-v2` | `optimised-v3` | `optimised-v4` |
|-----------------|-----------------|----------------|----------------|----------------|
| Build Time      | TBD             | N/A            | TBD            | N/A            |
| Push Time       | TBD             | N/A            | N/A            | N/A            |
| Final Image Size| N/A             | TBD            | N/A            | TBD            |
| Startup Time    | N/A             | TBD            | N/A            | TBD            |
| Memory Usage    | N/A             | N/A            | N/A            | TBD            |

---

## How to Run

Clone the repository and switch to the desired branch to test the optimisations:

```bash
# Clone the repository
git clone https://github.com/yourusername/java-optimized.git

# Switch to a branch
git checkout optimised-v1
```

Build the Docker image:

```bash
docker build -t java-optimized .
```

Run the container:

```bash
docker run --rm java-optimized
```

---

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues to discuss further optimisations.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

