import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateVideoVisitStatus keeps of each PreviewVideoVisit response.
struct PropagateVideoVisitStatusRecord {
    var status: String
    var referenceID: String
    var correlationID: String
}

/// Where PropagateVideoVisitStatus hands each record.
protocol PropagateVideoVisitStatusTarget {
    func forward(_ rec: PropagateVideoVisitStatusRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxQueryService.
struct PropagateVideoVisitStatusCareInboxQuery: PropagateVideoVisitStatusTarget {
    let client: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>

    func forward(_ rec: PropagateVideoVisitStatusRecord) async throws {
        _ = try await client.suggestCareInboxes(.with {
            $0.filter.region = rec.status
        })
    }
}

/// Hands records to acme.careplans.v1.CareGoalLifecycleService.
struct PropagateVideoVisitStatusCareGoalLifecycle: PropagateVideoVisitStatusTarget {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func forward(_ rec: PropagateVideoVisitStatusRecord) async throws {
        _ = try await client.getCareGoalLifecycle(.with {
            $0.careGoalID = rec.correlationID
        })
    }
}

/// Hands records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct PropagateVideoVisitStatusBoxOfficeSaleCalculation: PropagateVideoVisitStatusTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func forward(_ rec: PropagateVideoVisitStatusRecord) async throws {
        _ = try await client.getBoxOfficeSaleRates(.with {
            $0.boxOfficeSaleID = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateVideoVisitStatusLogOnly: PropagateVideoVisitStatusTarget {
    let logger = Logger(label: "acme.propagate-video-visit-status")

    func forward(_ rec: PropagateVideoVisitStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitValidationService/PreviewVideoVisit and hands what it keeps to the sink of its kind.
enum PropagateVideoVisitStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)
        let response = try await reader.previewVideoVisit(.with { $0.reason = "current-propagate-video-visit-status" })
        let record = PropagateVideoVisitStatusRecord(
            status: response.outcome.status,
            referenceID: response.outcome.referenceID,
            correlationID: response.result.correlationID
        )
        try await deliver("care-goal-lifecycle", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PropagateVideoVisitStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any PropagateVideoVisitStatusTarget = PropagateVideoVisitStatusLogOnly()
        switch kind {
        case "care-inbox-query":
            sink = PropagateVideoVisitStatusCareInboxQuery(client: Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: mesh))
        case "care-goal-lifecycle":
            sink = PropagateVideoVisitStatusCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh))
        case "box-office-sale-calculation":
            sink = PropagateVideoVisitStatusBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
