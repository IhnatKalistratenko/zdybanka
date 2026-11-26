FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app
COPY *.slnx .
COPY Zdybanka.API/*.csproj ./Zdybanka.API/
COPY Zdybanka.Application/*.csproj ./Zdybanka.Application/
COPY Zdybanka.Core/*.csproj ./Zdybanka.Core/
COPY Zdybanka.Data/*.csproj ./Zdybanka.Data/
COPY Zdybanka.Infrastructure/*.csproj ./Zdybanka.Infrastructure/
COPY Zdybanka.Tests/*.csproj ./Zdybanka.Tests/

RUN dotnet restore

COPY . .
WORKDIR /app/Zdybanka.API
RUN dotnet publish -c release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 5000
ENTRYPOINT [ "dotnet", "Zdybanka.API.dll" ]
