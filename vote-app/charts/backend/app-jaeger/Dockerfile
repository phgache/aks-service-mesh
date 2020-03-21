FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS builder
WORKDIR /app

# caches restore result by copying csproj file separately
COPY *.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish --output /app/ --configuration Release
RUN sed -n 's:.*<AssemblyName>\(.*\)</AssemblyName>.*:\1:p' *.csproj > __assemblyname
RUN if [ ! -s __assemblyname ]; then filename=$(ls *.csproj); echo ${filename%.*} > __assemblyname; fi

# Stage 2
FROM mcr.microsoft.com/dotnet/core/aspnet:2.2

RUN apt-get update && apt-get install wget -y

WORKDIR /app
COPY --from=builder /app .

ENV PORT 8081
ENV ASPNETCORE_URLS http://+:8081
EXPOSE 8081

ENTRYPOINT dotnet $(cat /app/__assemblyname).dll
