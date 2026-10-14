import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryAppointmentWorkflowMessage keeps of each AdvanceAppointmentWorkflow response.
struct CarryAppointmentWorkflowMessageRecord {
    var message: String
    var status: String
    var referenceID: String
    var resultStatus: String
}

/// Where CarryAppointmentWorkflowMessage hands each record.
protocol CarryAppointmentWorkflowMessageDestination {
    func forward(_ rec: CarryAppointmentWorkflowMessageRecord) async throws
}

/// Writes records to acme.onboarding.v1.OnboardingPlanQueryService.
struct CarryAppointmentWorkflowMessageOnboardingPlanQuery: CarryAppointmentWorkflowMessageDestination {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func forward(_ rec: CarryAppointmentWorkflowMessageRecord) async throws {
        let request = Acme_Onboarding_V1_PeekOnboardingPlanRequest.with {
            $0.onboardingPlanID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekOnboardingPlan(request)
        }
    }
}

/// Writes records to acme.careplans.v1.CarePlanLifecycleService.
struct CarryAppointmentWorkflowMessageCarePlanLifecycle: CarryAppointmentWorkflowMessageDestination {
    let client: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>

    func forward(_ rec: CarryAppointmentWorkflowMessageRecord) async throws {
        _ = try await client.suspendCarePlan(.with {
            $0.details.reasonCode = rec.status
            $0.reason = rec.referenceID
            $0.carePlanID = rec.resultStatus
        })
    }
}

/// Reads acme.appointments.v1.AppointmentWorkflowService/AdvanceAppointmentWorkflow and hands what it keeps to the sink of its kind.
enum CarryAppointmentWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_AppointmentWorkflowService.Client(wrapping: mesh)
        let response = try await reader.advanceAppointmentWorkflow(.with { $0.reason = "live-carry-appointment-workflow-message" })
        let entry = CarryAppointmentWorkflowMessageRecord(
            message: response.result.message,
            status: response.outcome.status,
            referenceID: response.outcome.referenceID,
            resultStatus: Kit.Text.normalize(response.result.status)
        )
        let sinks: [String: any CarryAppointmentWorkflowMessageDestination] = [
            "onboarding-plan-query": CarryAppointmentWorkflowMessageOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)),
            "care-plan-lifecycle": CarryAppointmentWorkflowMessageCarePlanLifecycle(client: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["CARRY_APPOINTMENT_WORKFLOW_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.forward(entry)
    }
}
