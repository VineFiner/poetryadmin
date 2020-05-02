import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import JWT
import Mailgun
import QueuesRedisDriver

public func configure(_ app: Application) throws {
    // MARK: JWT
    if app.environment != .testing {
        let jwksFilePath = app.directory.workingDirectory + (Environment.get("JWKS_KEYPAIR_FILE") ?? "keypair.jwks")
         guard
             let jwks = FileManager.default.contents(atPath: jwksFilePath),
             let jwksString = String(data: jwks, encoding: .utf8)
             else {
                 fatalError("Failed to load JWKS Keypair file at: \(jwksFilePath)")
         }
         try app.jwt.signers.use(jwksJSON: jwksString)
    }
    
    // MARK: Database
    // Configure PostgreSQL database
    if app.environment == .production {
        app.databases.use(
            .postgres(
                hostname: Environment.get("POSTGRES_HOSTNAME") ?? "localhost",
                username: Environment.get("POSTGRES_USERNAME") ?? "vapor",
                password: Environment.get("POSTGRES_PASSWORD") ?? "password",
                database: Environment.get("POSTGRES_DATABASE") ?? "vapor"
            ), as: .psql)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    }
    
    // MARK: Middleware
    app.middleware = .init()
    app.middleware.use(ErrorMiddleware.custom(environment: app.environment))
    
    // MARK: Model Middleware
    
    // MARK: Mailgun
    app.mailgun.configuration = .environment
    app.mailgun.defaultDomain = .sandbox
    
    // MARK: App Config
    app.config = .environment
    
    try routes(app)
    try migrations(app)
    // 这里是任务
    try queues(app)
    // 配置服务
    try services(app)
    
    
    if app.environment == .development {
        try app.autoMigrate().wait()
    }
    
    if app.environment == .custom(name: "processJobs") {
        // 这里是定时任务
        try app.queues.startInProcessJobs()
    }
}
