# Use Eclipse Temurin JDK 17
FROM eclipse-temurin:17-jdk

# Expose your application's port
EXPOSE 8082

COPY target/timesheet-devops-1.0.jar app.jar


# Run the application
ENTRYPOINT ["java","-jar","/timesheet-devops-1.0.jar"]
