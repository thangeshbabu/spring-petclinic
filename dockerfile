FROM maven:3.9.5-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
RUN chmod +x mvnw

RUN ./mvnw dependency:go-offline -B

COPY src src/
RUN ./mvnw clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -D appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=build --chown=appuser:appgroup /app/target/spring-petclinic-*.jar app.jar

# Switch to non-root user
USER appuser

ENV SERVER_PORT=8080
# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
