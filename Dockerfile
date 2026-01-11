# Build stage
FROM maven:3.9.4-eclipse-temurin-17 AS build
WORKDIR /workspace

# Copy only pom and download dependencies first for caching
COPY pom.xml .
RUN mvn -B -f pom.xml -DskipTests dependency:go-offline

# Copy source
COPY src ./src

# Package the application
RUN mvn -B -DskipTests package

# Runtime stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /workspace/target/demo-0.0.1-SNAPSHOT.jar /app/demo.jar
ENV JAVA_OPTS=""
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/demo.jar"]

