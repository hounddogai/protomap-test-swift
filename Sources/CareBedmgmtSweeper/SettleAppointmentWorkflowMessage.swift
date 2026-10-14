import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleAppointmentWorkflowMessage keeps of each RetryAppointmentWorkflow response.
struct SettleAppointmentWorkflowMessageRecord {
    var message: String
    var correlationID: String
    var status: String
}

/// Where SettleAppointmentWorkflowMessage hands each record.
protocol SettleAppointmentWorkflowMessageWriter {
    func deliver(_ rec: SettleAppointmentWorkflowMessageRecord) async throws
}

/// Writes records to acme.patients.v1.AllergyValidationService.
struct SettleAppointmentWorkflowMessageAllergyValidation: SettleAppointmentWorkflowMessageWriter {
    let client: Acme_Patients_V1_AllergyValidationService.Client<MeshTransport>

    func deliver(_ rec: SettleAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.previewAllergy(.with {
            $0.reason = rec.status
        })
    }
}

/// Hands records to acme.careplans.v1.VitalLifecycleService.
struct SettleAppointmentWorkflowMessageVitalLifecycle: SettleAppointmentWorkflowMessageWriter {
    let client: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>

    func deliver(_ rec: SettleAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.suspendVital(.with {
            $0.details.reasonCode = rec.status
            $0.vitalID = rec.correlationID
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanQueryService.
struct SettleAppointmentWorkflowMessageCarePlanQuery: SettleAppointmentWorkflowMessageWriter {
    let client: Acme_Careplans_V1_CarePlanQueryService.Client<MeshTransport>

    func deliver(_ rec: SettleAppointmentWorkflowMessageRecord) async throws {
        let request = Acme_Careplans_V1_CountCarePlansRequest.with {
            $0.filter.query = rec.correlationID
            $0.orderBy = rec.message
            $0.filter.ownerID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countCarePlans(request)
        }
    }
}

/// Hands records to acme.appointments.v1.ProviderValidationService.
struct SettleAppointmentWorkflowMessageProviderValidation: SettleAppointmentWorkflowMessageWriter {
    let client: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>

    func deliver(_ rec: SettleAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.explainProviderDecision(.with {
            $0.reason = rec.status
            $0.details.locale = rec.message
            $0.provider.providerID = rec.correlationID
        })
    }
}

/// Reads acme.appointments.v1.AppointmentWorkflowService/RetryAppointmentWorkflow and hands what it keeps to the sink of its kind.
enum SettleAppointmentWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_AppointmentWorkflowService.Client(wrapping: mesh)
        let response = try await reader.retryAppointmentWorkflow(.with { $0.reason = "nightly-settle-appointment-workflow-message" })
        let rec = SettleAppointmentWorkflowMessageRecord(
            message: response.outcome.message,
            correlationID: response.result.correlationID,
            status: response.outcome.status
        )
        let sinks: [String: any SettleAppointmentWorkflowMessageWriter] = [
            "allergy-validation": SettleAppointmentWorkflowMessageAllergyValidation(client: Acme_Patients_V1_AllergyValidationService.Client(wrapping: mesh)),
            "vital-lifecycle": SettleAppointmentWorkflowMessageVitalLifecycle(client: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: mesh)),
            "care-plan-query": SettleAppointmentWorkflowMessageCarePlanQuery(client: Acme_Careplans_V1_CarePlanQueryService.Client(wrapping: mesh)),
            "provider-validation": SettleAppointmentWorkflowMessageProviderValidation(client: Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh)),
        ]
        try await route("provider-validation", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SettleAppointmentWorkflowMessageRecord, _ sinks: [String: any SettleAppointmentWorkflowMessageWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
