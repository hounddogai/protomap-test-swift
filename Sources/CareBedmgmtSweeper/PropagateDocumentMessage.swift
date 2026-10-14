import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateDocumentMessage keeps of each DeleteDocument response.
struct PropagateDocumentMessageRecord {
    var message: String
    var status: String
}

/// Where PropagateDocumentMessage hands each record.
protocol PropagateDocumentMessageDestination {
    func write(_ rec: PropagateDocumentMessageRecord) async throws
}

/// Passes records to acme.appointments.v1.AppointmentValidationService.
struct PropagateDocumentMessageAppointmentValidation: PropagateDocumentMessageDestination {
    let client: Acme_Appointments_V1_AppointmentValidationService.Client<MeshTransport>

    func write(_ rec: PropagateDocumentMessageRecord) async throws {
        let request = Acme_Appointments_V1_GetAppointmentRulesRequest.with {
            $0.appointmentID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getAppointmentRules(request)
        }
    }
}

/// Sends records to acme.careplans.v1.CarePlanApprovalService.
struct PropagateDocumentMessageCarePlanApproval: PropagateDocumentMessageDestination {
    let client: Acme_Careplans_V1_CarePlanApprovalService.Client<MeshTransport>

    func write(_ rec: PropagateDocumentMessageRecord) async throws {
        let request = Acme_Careplans_V1_DelegateCarePlanApprovalRequest.with {
            $0.carePlan.number = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.delegateCarePlanApproval(request)
        }
    }
}

/// Hands records to acme.itsm.v1.IncidentCalculationService.
struct PropagateDocumentMessageIncidentCalculation: PropagateDocumentMessageDestination {
    let client: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>

    func write(_ rec: PropagateDocumentMessageRecord) async throws {
        let request = Acme_Itsm_V1_GetIncidentRatesRequest.with {
            $0.incidentID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getIncidentRates(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateDocumentMessageLogOnly: PropagateDocumentMessageDestination {
    let logger = Logger(label: "acme.propagate-document-message")

    func write(_ rec: PropagateDocumentMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.documents.v1.DocumentService/DeleteDocument and hands what it keeps to the sink of its kind.
enum PropagateDocumentMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Documents_V1_DocumentService.Client(wrapping: mesh)
        let reply = try await reader.deleteDocument(.with { $0.reason = "live-propagate-document-message" })
        let entry = PropagateDocumentMessageRecord(
            message: reply.result.message,
            status: reply.result.status
        )
        try await dispatch("appointment-validation", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PropagateDocumentMessageRecord, _ mesh: MeshClient) async throws {
        var write: (PropagateDocumentMessageRecord) async throws -> Void = PropagateDocumentMessageLogOnly().write
        switch kind {
        case "appointment-validation":
            write = PropagateDocumentMessageAppointmentValidation(client: Acme_Appointments_V1_AppointmentValidationService.Client(wrapping: mesh)).write
        case "care-plan-approval":
            write = PropagateDocumentMessageCarePlanApproval(client: Acme_Careplans_V1_CarePlanApprovalService.Client(wrapping: mesh)).write
        case "incident-calculation":
            write = PropagateDocumentMessageIncidentCalculation(client: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
