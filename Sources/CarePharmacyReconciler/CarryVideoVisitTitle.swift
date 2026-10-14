import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryVideoVisitTitle keeps of each CloneVideoVisit response.
struct CarryVideoVisitTitleRecord {
    var title: String
    var status: String
    var message: String
}

/// Where CarryVideoVisitTitle hands each record.
protocol CarryVideoVisitTitleWriter {
    func deliver(_ rec: CarryVideoVisitTitleRecord) async throws
}

/// Sends records to acme.patients.v1.MedicalRecordReportingService.
struct CarryVideoVisitTitleMedicalRecordReporting: CarryVideoVisitTitleWriter {
    let client: Acme_Patients_V1_MedicalRecordReportingService.Client<MeshTransport>

    func deliver(_ rec: CarryVideoVisitTitleRecord) async throws {
        _ = try await client.scheduleMedicalRecordReport(.with {
            $0.details.format = rec.title
            $0.details.cron = rec.status
            $0.reason = rec.message
        })
    }
}

/// Sends records to acme.appointments.v1.AppointmentApprovalService.
struct CarryVideoVisitTitleAppointmentApproval: CarryVideoVisitTitleWriter {
    let client: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>

    func deliver(_ rec: CarryVideoVisitTitleRecord) async throws {
        _ = try await client.submitAppointment(.with {
            $0.details.comment = rec.title
            $0.details.approverEmail = rec.message
        })
    }
}

/// Writes records to acme.concessions.v1.ConcessionStandQueryService.
struct CarryVideoVisitTitleConcessionStandQuery: CarryVideoVisitTitleWriter {
    let client: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>

    func deliver(_ rec: CarryVideoVisitTitleRecord) async throws {
        let request = Acme_Concessions_V1_PeekConcessionStandRequest.with {
            $0.concessionStandID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekConcessionStand(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryVideoVisitTitleLogOnly: CarryVideoVisitTitleWriter {
    let logger = Logger(label: "acme.carry-video-visit-title")

    func deliver(_ rec: CarryVideoVisitTitleRecord) async throws {
        logger.info("No sink for record", metadata: ["title": .string(rec.title)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitService/CloneVideoVisit and hands what it keeps to the sink of its kind.
enum CarryVideoVisitTitle {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)
        let found = try await reader.cloneVideoVisit(.with { $0.requestID = "main-carry-video-visit-title" })
        let entry = CarryVideoVisitTitleRecord(
            title: Kit.Text.normalize(found.videoVisit.title),
            status: Kit.Text.normalize(found.result.status),
            message: Kit.Text.normalize(found.result.message)
        )
        try await dispatch("medical-record-reporting", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: CarryVideoVisitTitleRecord, _ mesh: MeshClient) async throws {
        var write: (CarryVideoVisitTitleRecord) async throws -> Void = CarryVideoVisitTitleLogOnly().deliver
        switch kind {
        case "medical-record-reporting":
            write = CarryVideoVisitTitleMedicalRecordReporting(client: Acme_Patients_V1_MedicalRecordReportingService.Client(wrapping: mesh)).deliver
        case "appointment-approval":
            write = CarryVideoVisitTitleAppointmentApproval(client: Acme_Appointments_V1_AppointmentApprovalService.Client(wrapping: mesh)).deliver
        case "concession-stand-query":
            write = CarryVideoVisitTitleConcessionStandQuery(client: Acme_Concessions_V1_ConcessionStandQueryService.Client(wrapping: mesh)).deliver
        default:
            break
        }
        try await write(rec)
    }
}
