import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryCarePlansMessage keeps of each CountCarePlans response.
struct CarryCarePlansMessageRecord {
    var message: String
    var correlationID: String
    var status: String
}

/// Where CarryCarePlansMessage hands each record.
protocol CarryCarePlansMessageSink {
    func apply(_ rec: CarryCarePlansMessageRecord) async throws
}

/// Sends records to acme.documents.v1.DocumentQueryService.
struct CarryCarePlansMessageDocumentQuery: CarryCarePlansMessageSink {
    let client: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>

    func apply(_ rec: CarryCarePlansMessageRecord) async throws {
        _ = try await client.lookupDocument(.with {
            $0.documentID = rec.status
        })
    }
}

/// Sends records to acme.patients.v1.PatientLifecycleService.
struct CarryCarePlansMessagePatientLifecycle: CarryCarePlansMessageSink {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func apply(_ rec: CarryCarePlansMessageRecord) async throws {
        _ = try await client.renewPatient(.with {
            $0.details.reasonCode = rec.correlationID
            $0.patientID = rec.message
            $0.reason = rec.status
        })
    }
}

/// Hands records to acme.metrics.v1.MetricSeriesService.
struct CarryCarePlansMessageMetricSeries: CarryCarePlansMessageSink {
    let client: Acme_Metrics_V1_MetricSeriesService.Client<MeshTransport>

    func apply(_ rec: CarryCarePlansMessageRecord) async throws {
        let request = Acme_Metrics_V1_ListMetricSeriesesRequest.with {
            $0.page.pageToken = rec.message
            $0.filter.query = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listMetricSerieses(request)
        }
    }
}

/// Writes records to acme.careplans.v1.CareGoalQueryService.
struct CarryCarePlansMessageCareGoalQuery: CarryCarePlansMessageSink {
    let client: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>

    func apply(_ rec: CarryCarePlansMessageRecord) async throws {
        _ = try await client.browseCareGoals(.with {
            $0.filter.query = rec.correlationID
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.status
        })
    }
}

/// Reads acme.careplans.v1.CarePlanQueryService/CountCarePlans and hands what it keeps to the sink of its kind.
enum CarryCarePlansMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: mesh)
        let got = try await reader.countCarePlans(.with { $0.orderBy = "nightly-carry-care-plans-message" })
        let row = CarryCarePlansMessageRecord(
            message: got.result.message,
            correlationID: got.result.correlationID,
            status: got.result.status
        )
        let sinks: [any CarryCarePlansMessageSink] = [
            CarryCarePlansMessageDocumentQuery(client: Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)),
            CarryCarePlansMessagePatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)),
            CarryCarePlansMessageMetricSeries(client: Acme_Metrics_V1_MetricSeriesService.Client(wrapping: mesh)),
            CarryCarePlansMessageCareGoalQuery(client: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.apply(row)
        }
    }
}
