import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateAccessPolicyName keeps of each LookupAccessPolicy response.
struct PropagateAccessPolicyNameRecord {
    var name: String
    var correlationID: String
    var status: String
}

/// Where PropagateAccessPolicyName hands each record.
protocol PropagateAccessPolicyNameTarget {
    func write(_ rec: PropagateAccessPolicyNameRecord) async throws
}

/// Writes records to acme.appointments.v1.ClinicSlotValidationService.
struct PropagateAccessPolicyNameClinicSlotValidation: PropagateAccessPolicyNameTarget {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func write(_ rec: PropagateAccessPolicyNameRecord) async throws {
        _ = try await client.validateClinicSlot(.with {
            $0.clinicSlotID = rec.correlationID
        })
    }
}

/// Sends records to acme.ticketing.v1.TicketService.
struct PropagateAccessPolicyNameTicket: PropagateAccessPolicyNameTarget {
    let client: Acme_Ticketing_V1_TicketService.Client<MeshTransport>

    func write(_ rec: PropagateAccessPolicyNameRecord) async throws {
        _ = try await client.deleteTicket(.with {
            $0.ticketID = rec.correlationID
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationSyncService.
struct PropagateAccessPolicyNameMedicationSync: PropagateAccessPolicyNameTarget {
    let client: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>

    func write(_ rec: PropagateAccessPolicyNameRecord) async throws {
        _ = try await client.listMedicationConflicts(.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.name
            $0.orderBy = rec.status
        })
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteWorkflowService.
struct PropagateAccessPolicyNameVisitNoteWorkflow: PropagateAccessPolicyNameTarget {
    let client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client<MeshTransport>

    func write(_ rec: PropagateAccessPolicyNameRecord) async throws {
        _ = try await client.inspectVisitNoteWorkflow(.with {
            $0.visitNoteID = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateAccessPolicyNameLogOnly: PropagateAccessPolicyNameTarget {
    let logger = Logger(label: "acme.propagate-access-policy-name")

    func write(_ rec: PropagateAccessPolicyNameRecord) async throws {
        logger.info("No sink for record", metadata: ["name": .string(rec.name)])
    }
}

/// Reads acme.authorization.v1.AccessPolicyQueryService/LookupAccessPolicy and hands what it keeps to the sink of its kind.
enum PropagateAccessPolicyName {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)
        let response = try await reader.lookupAccessPolicy(.with { $0.accessPolicyID = "main-propagate-access-policy-name" })
        let entry = PropagateAccessPolicyNameRecord(
            name: response.accessPolicy.name,
            correlationID: response.result.correlationID,
            status: response.result.status
        )
        try await deliver("ticket", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PropagateAccessPolicyNameRecord, _ mesh: MeshClient) async throws {
        var sink: any PropagateAccessPolicyNameTarget = PropagateAccessPolicyNameLogOnly()
        switch kind {
        case "clinic-slot-validation":
            sink = PropagateAccessPolicyNameClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh))
        case "ticket":
            sink = PropagateAccessPolicyNameTicket(client: Acme_Ticketing_V1_TicketService.Client(wrapping: mesh))
        case "medication-sync":
            sink = PropagateAccessPolicyNameMedicationSync(client: Acme_Prescriptions_V1_MedicationSyncService.Client(wrapping: mesh))
        case "visit-note-workflow":
            sink = PropagateAccessPolicyNameVisitNoteWorkflow(client: Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
