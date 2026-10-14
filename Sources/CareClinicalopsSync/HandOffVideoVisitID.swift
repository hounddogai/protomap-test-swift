import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffVideoVisitID keeps of each ApproveVideoVisit response.
struct HandOffVideoVisitIDRecord {
    var correlationID: String
    var message: String
    var status: String
    var resultMessage: String
}

/// Where HandOffVideoVisitID hands each record.
protocol HandOffVideoVisitIDDestination {
    func forward(_ rec: HandOffVideoVisitIDRecord) async throws
}

/// Hands records to acme.patientapp.v1.CareInboxNotificationService.
struct HandOffVideoVisitIDCareInboxNotification: HandOffVideoVisitIDDestination {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func forward(_ rec: HandOffVideoVisitIDRecord) async throws {
        let request = Acme_Patientapp_V1_SendCareInboxTestNoticeRequest.with {
            $0.details.channel = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.sendCareInboxTestNotice(request)
        }
    }
}

/// Hands records to acme.patients.v1.PatientApprovalService.
struct HandOffVideoVisitIDPatientApproval: HandOffVideoVisitIDDestination {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func forward(_ rec: HandOffVideoVisitIDRecord) async throws {
        _ = try await client.escalatePatient(.with {
            $0.details.approverEmail = rec.resultMessage
            $0.reason = rec.status
        })
    }
}

/// Writes records to acme.seating.v1.SeatMapService.
struct HandOffVideoVisitIDSeatMap: HandOffVideoVisitIDDestination {
    let client: Acme_Seating_V1_SeatMapService.Client<MeshTransport>

    func forward(_ rec: HandOffVideoVisitIDRecord) async throws {
        _ = try await client.listSeatMaps(.with {
            $0.orderBy = rec.correlationID
            $0.filter.query = rec.message
            $0.filter.ownerID = rec.resultMessage
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordQueryService.
struct HandOffVideoVisitIDMedicalRecordQuery: HandOffVideoVisitIDDestination {
    let client: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>

    func forward(_ rec: HandOffVideoVisitIDRecord) async throws {
        let request = Acme_Patients_V1_FindMedicalRecordsRequest.with {
            $0.filter.region = rec.status
            $0.orderBy = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findMedicalRecords(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct HandOffVideoVisitIDLogOnly: HandOffVideoVisitIDDestination {
    let logger = Logger(label: "acme.hand-off-video-visit-id")

    func forward(_ rec: HandOffVideoVisitIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitApprovalService/ApproveVideoVisit and hands what it keeps to the sink of its kind.
enum HandOffVideoVisitID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)
        let reply = try await source.approveVideoVisit(.with { $0.reason = "nightly-hand-off-video-visit-id" })
        let rec = HandOffVideoVisitIDRecord(
            correlationID: reply.result.correlationID,
            message: reply.outcome.message,
            status: reply.outcome.status,
            resultMessage: Kit.Text.normalize(reply.result.message)
        )
        try await dispatch("medical-record-query", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: HandOffVideoVisitIDRecord, _ mesh: MeshClient) async throws {
        var write: (HandOffVideoVisitIDRecord) async throws -> Void = HandOffVideoVisitIDLogOnly().forward
        switch kind {
        case "care-inbox-notification":
            write = HandOffVideoVisitIDCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh)).forward
        case "patient-approval":
            write = HandOffVideoVisitIDPatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)).forward
        case "seat-map":
            write = HandOffVideoVisitIDSeatMap(client: Acme_Seating_V1_SeatMapService.Client(wrapping: mesh)).forward
        case "medical-record-query":
            write = HandOffVideoVisitIDMedicalRecordQuery(client: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)).forward
        default:
            break
        }
        try await write(rec)
    }
}
