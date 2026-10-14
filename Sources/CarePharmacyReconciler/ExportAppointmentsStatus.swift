import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportAppointmentsStatus keeps of each LintAppointments response.
struct ExportAppointmentsStatusRecord {
    var status: String
    var correlationID: String
    var message: String
}

/// Where ExportAppointmentsStatus hands each record.
protocol ExportAppointmentsStatusWriter {
    func apply(_ rec: ExportAppointmentsStatusRecord) async throws
}

/// Passes records to acme.onboarding.v1.OnboardingPlanQueryService.
struct ExportAppointmentsStatusOnboardingPlanQuery: ExportAppointmentsStatusWriter {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func apply(_ rec: ExportAppointmentsStatusRecord) async throws {
        _ = try await client.summarizeOnboardingPlans(.with {
            $0.onboardingPlanID = rec.correlationID
            $0.details.format = rec.message
        })
    }
}

/// Passes records to acme.telehealth.v1.VideoVisitWorkflowService.
struct ExportAppointmentsStatusVideoVisitWorkflow: ExportAppointmentsStatusWriter {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func apply(_ rec: ExportAppointmentsStatusRecord) async throws {
        _ = try await client.startVideoVisitWorkflow(.with {
            $0.details.initiatedBy = rec.message
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanValidationService.
struct ExportAppointmentsStatusCarePlanValidation: ExportAppointmentsStatusWriter {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func apply(_ rec: ExportAppointmentsStatusRecord) async throws {
        let request = Acme_Careplans_V1_NormalizeCarePlanRequest.with {
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.normalizeCarePlan(request)
        }
    }
}

/// Passes records to acme.appointments.v1.AppointmentQueryService.
struct ExportAppointmentsStatusAppointmentQuery: ExportAppointmentsStatusWriter {
    let client: Acme_Appointments_V1_AppointmentQueryService.Client<MeshTransport>

    func apply(_ rec: ExportAppointmentsStatusRecord) async throws {
        let request = Acme_Appointments_V1_LookupAppointmentRequest.with {
            $0.appointmentID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lookupAppointment(request)
        }
    }
}

/// Reads acme.appointments.v1.AppointmentValidationService/LintAppointments and hands what it keeps to the sink of its kind.
enum ExportAppointmentsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_AppointmentValidationService.Client(wrapping: mesh)
        let response = try await reader.lintAppointments(.with { $0.reason = "primary-export-appointments-status" })
        let entry = ExportAppointmentsStatusRecord(
            status: response.outcome.status,
            correlationID: response.result.correlationID,
            message: Kit.Text.normalize(response.outcome.message)
        )
        let sinks: [any ExportAppointmentsStatusWriter] = [
            ExportAppointmentsStatusOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)),
            ExportAppointmentsStatusVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)),
            ExportAppointmentsStatusCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)),
            ExportAppointmentsStatusAppointmentQuery(client: Acme_Appointments_V1_AppointmentQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[3].apply(entry)
    }
}
