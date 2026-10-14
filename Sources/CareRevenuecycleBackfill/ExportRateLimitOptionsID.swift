import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportRateLimitOptionsID keeps of each CompareRateLimitOptions response.
struct ExportRateLimitOptionsIDRecord {
    var correlationID: String
    var status: String
    var name: String
}

/// Where ExportRateLimitOptionsID hands each record.
protocol ExportRateLimitOptionsIDDestination {
    func apply(_ rec: ExportRateLimitOptionsIDRecord) async throws
}

/// Passes records to acme.fleet.v1.VehicleService.
struct ExportRateLimitOptionsIDVehicle: ExportRateLimitOptionsIDDestination {
    let client: Acme_Fleet_V1_VehicleService.Client<MeshTransport>

    func apply(_ rec: ExportRateLimitOptionsIDRecord) async throws {
        _ = try await client.createVehicle(.with {
            $0.vehicle.vehicleID = rec.status
            $0.requestID = rec.correlationID
        })
    }
}

/// Passes records to acme.telematics.v1.TelemetryReadingQueryService.
struct ExportRateLimitOptionsIDTelemetryReadingQuery: ExportRateLimitOptionsIDDestination {
    let client: Acme_Telematics_V1_TelemetryReadingQueryService.Client<MeshTransport>

    func apply(_ rec: ExportRateLimitOptionsIDRecord) async throws {
        _ = try await client.suggestTelemetryReadings(.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.name
        })
    }
}

/// Reads acme.ratelimiting.v1.RateLimitCalculationService/CompareRateLimitOptions and hands what it keeps to the sink of its kind.
enum ExportRateLimitOptionsID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)
        let response = try await upstream.compareRateLimitOptions(.with { $0.rateLimitID = "live-export-rate-limit-options-id" })
        let rec = ExportRateLimitOptionsIDRecord(
            correlationID: response.result.correlationID,
            status: Kit.Text.normalize(response.result.status),
            name: response.rateLimit.name
        )
        let sinks: [String: any ExportRateLimitOptionsIDDestination] = [
            "vehicle": ExportRateLimitOptionsIDVehicle(client: Acme_Fleet_V1_VehicleService.Client(wrapping: mesh)),
            "telemetry-reading-query": ExportRateLimitOptionsIDTelemetryReadingQuery(client: Acme_Telematics_V1_TelemetryReadingQueryService.Client(wrapping: mesh)),
        ]
        try await route("vehicle", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ExportRateLimitOptionsIDRecord, _ sinks: [String: any ExportRateLimitOptionsIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
