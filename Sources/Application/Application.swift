import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudFoundryConfig
import SwiftMetrics
import SwiftMetricsDash
import BluemixObjectStorage

public let router = Router()
public let manager = ConfigurationManager()
public var port: Int = 8080

internal var objectStorage: ObjectStorage?

public func initialize() throws {

    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: router)

    let objectStorageService = try manager.getObjectStorageService(name: "bobble-Object-Storage-6bf5")
    objectStorage = ObjectStorage(service: objectStorageService)
    try objectStorage?.connectSync(service: objectStorageService)

    router.all("/*", middleware: BodyParser())
    router.all("/", middleware: StaticFileServer())
    initializeSwaggerRoute(path: ConfigurationManager.BasePath.project.path + "/definitions/bobble.yaml")
    initializeProductRoutes()
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
