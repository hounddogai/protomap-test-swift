import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPrescriptionReportNotes keeps of each FetchPrescriptionReport response.
struct RelayPrescriptionReportNotesRecord {
    var notes: String
    var message: String
    var prescriptionID: String
    var correlationID: String
}

/// Where RelayPrescriptionReportNotes hands each record.
protocol RelayPrescriptionReportNotesTarget {
    func apply(_ rec: RelayPrescriptionReportNotesRecord) async throws
}

/// Hands records to acme.corporateevents.v1.CorporateEventQueryService.
struct RelayPrescriptionReportNotesCorporateEventQuery: RelayPrescriptionReportNotesTarget {
    let client: Acme_Corporateevents_V1_CorporateEventQueryService.Client<MeshTransport>

    func apply(_ rec: RelayPrescriptionReportNotesRecord) async throws {
        _ = try await client.countCorporateEvents(.with {
            $0.filter.query = rec.message
            $0.filter.ownerID = rec.prescriptionID
        })
    }
}

/// Hands records to acme.prescriptions.v1.RefillWorkflowService.
struct RelayPrescriptionReportNotesRefillWorkflow: RelayPrescriptionReportNotesTarget {
    let client: Acme_Prescriptions_V1_RefillWorkflowService.Client<MeshTransport>

    func apply(_ rec: RelayPrescriptionReportNotesRecord) async throws {
        _ = try await client.resumeRefillWorkflow(.with {
            $0.refill.subject = rec.prescriptionID
        })
    }
}

/// Passes records to acme.careplans.v1.CareGoalQueryService.
struct RelayPrescriptionReportNotesCareGoalQuery: RelayPrescriptionReportNotesTarget {
    let client: Acme_Careplans_V1_CareGoalQueryService.Client<MeshTransport>

    func apply(_ rec: RelayPrescriptionReportNotesRecord) async throws {
        _ = try await client.suggestCareGoals(.with {
            $0.page.pageToken = rec.message
            $0.filter.query = rec.notes
        })
    }
}

/// Hands records to acme.patients.v1.PatientLifecycleService.
struct RelayPrescriptionReportNotesPatientLifecycle: RelayPrescriptionReportNotesTarget {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func apply(_ rec: RelayPrescriptionReportNotesRecord) async throws {
        _ = try await client.expirePatient(.with {
            $0.reason = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayPrescriptionReportNotesLogOnly: RelayPrescriptionReportNotesTarget {
    let logger = Logger(label: "acme.relay-prescription-report-notes")

    func apply(_ rec: RelayPrescriptionReportNotesRecord) async throws {
        logger.info("No sink for record", metadata: ["notes": .string(rec.notes)])
    }
}

/// Reads acme.prescriptions.v1.PrescriptionReportingService/FetchPrescriptionReport and hands what it keeps to the sink of its kind.
enum RelayPrescriptionReportNotes {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_PrescriptionReportingService.Client(wrapping: mesh)
        let response = try await source.fetchPrescriptionReport(.with { $0.prescriptionID = "primary-relay-prescription-report-notes" })
        let record = RelayPrescriptionReportNotesRecord(
            notes: Kit.Text.normalize(response.prescription.notes),
            message: Kit.Text.normalize(response.result.message),
            prescriptionID: response.prescription.prescriptionID,
            correlationID: response.result.correlationID
        )
        try await dispatch("refill-workflow", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: RelayPrescriptionReportNotesRecord, _ mesh: MeshClient) async throws {
        var write: (RelayPrescriptionReportNotesRecord) async throws -> Void = RelayPrescriptionReportNotesLogOnly().apply
        switch kind {
        case "corporate-event-query":
            write = RelayPrescriptionReportNotesCorporateEventQuery(client: Acme_Corporateevents_V1_CorporateEventQueryService.Client(wrapping: mesh)).apply
        case "refill-workflow":
            write = RelayPrescriptionReportNotesRefillWorkflow(client: Acme_Prescriptions_V1_RefillWorkflowService.Client(wrapping: mesh)).apply
        case "care-goal-query":
            write = RelayPrescriptionReportNotesCareGoalQuery(client: Acme_Careplans_V1_CareGoalQueryService.Client(wrapping: mesh)).apply
        case "patient-lifecycle":
            write = RelayPrescriptionReportNotesPatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)).apply
        default:
            break
        }
        try await write(rec)
    }
}
