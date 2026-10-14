import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryProviderMessage keeps of each ScoreProvider response.
struct CarryProviderMessageRecord {
    var message: String
    var correlationID: String
    var status: String
}

/// Where CarryProviderMessage hands each record.
protocol CarryProviderMessageWriter {
    func send(_ rec: CarryProviderMessageRecord) async throws
}

/// Sends records to acme.appointments.v1.ProviderValidationService.
struct CarryProviderMessageProviderValidation: CarryProviderMessageWriter {
    let client: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>

    func send(_ rec: CarryProviderMessageRecord) async throws {
        let request = Acme_Appointments_V1_GetProviderRulesRequest.with {
            $0.providerID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getProviderRules(request)
        }
    }
}

/// Hands records to acme.metrics.v1.MetricSeriesService.
struct CarryProviderMessageMetricSeries: CarryProviderMessageWriter {
    let client: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>

    func send(_ rec: CarryProviderMessageRecord) async throws {
        _ = try await client.updateMetricSeries(.with {
            $0.metricSeries.code = rec.correlationID
            $0.metricSeries.name = rec.status
        })
    }
}

/// Sends records to acme.careplans.v1.CarePlanValidationService.
struct CarryProviderMessageCarePlanValidation: CarryProviderMessageWriter {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func send(_ rec: CarryProviderMessageRecord) async throws {
        _ = try await client.lintCarePlans(.with {
            $0.carePlanID = rec.status
            $0.reason = rec.correlationID
            $0.carePlan.number = rec.message
        })
    }
}

/// Reads acme.appointments.v1.ProviderValidationService/ScoreProvider and hands what it keeps to the sink of its kind.
enum CarryProviderMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh)
        let response = try await origin.scoreProvider(.with { $0.reason = "current-carry-provider-message" })
        let record = CarryProviderMessageRecord(
            message: response.result.message,
            correlationID: response.result.correlationID,
            status: response.result.status
        )
        let sinks: [String: any CarryProviderMessageWriter] = [
            "provider-validation": CarryProviderMessageProviderValidation(client: Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh)),
            "metric-series": CarryProviderMessageMetricSeries(client: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: mesh)),
            "care-plan-validation": CarryProviderMessageCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-plan-validation" {
                continue
            }
            try await sink.send(record)
        }
    }
}
