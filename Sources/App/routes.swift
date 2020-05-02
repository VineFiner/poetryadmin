import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.group("api") { api in
        // Authentication
        try api.register(collection: AuthenticationController())
    }
}
