import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryDispatchOrdersID keeps of each SuggestDispatchOrders response.
struct CarryDispatchOrdersIDRecord {
    var correlationID: String
    var nextPageToken: String
}

/// Where CarryDispatchOrdersID hands each record.
protocol CarryDispatchOrdersIDWriter {
    func send(_ rec: CarryDispatchOrdersIDRecord) async throws
}

/// Passes records to acme.patientapp.v1.CareInboxWorkflowService.
struct CarryDispatchOrdersIDCareInboxWorkflow: CarryDispatchOrdersIDWriter {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func send(_ rec: CarryDispatchOrdersIDRecord) async throws {
        _ = try await client.signalCareInboxWorkflow(.with {
            $0.careInboxID = rec.nextPageToken
            $0.details.step = rec.correlationID
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanService.
struct CarryDispatchOrdersIDCarePlan: CarryDispatchOrdersIDWriter {
    let client: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>

    func send(_ rec: CarryDispatchOrdersIDRecord) async throws {
        _ = try await client.listCarePlans(.with {
            $0.page.pageToken = rec.nextPageToken
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordLifecycleService.
struct CarryDispatchOrdersIDMedicalRecordLifecycle: CarryDispatchOrdersIDWriter {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func send(_ rec: CarryDispatchOrdersIDRecord) async throws {
        let request = Acme_Patients_V1_ActivateMedicalRecordRequest.with {
            $0.medicalRecordID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.activateMedicalRecord(request)
        }
    }
}

/// Sends records to acme.careplans.v1.CareGoalLifecycleService.
struct CarryDispatchOrdersIDCareGoalLifecycle: CarryDispatchOrdersIDWriter {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func send(_ rec: CarryDispatchOrdersIDRecord) async throws {
        _ = try await client.expireCareGoal(.with {
            $0.reason = rec.nextPageToken
        })
    }
}

/// Reads acme.dispatch.v1.DispatchOrderQueryService/SuggestDispatchOrders and hands what it keeps to the sink of its kind.
enum CarryDispatchOrdersID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)
        let reply = try await upstream.suggestDispatchOrders(.with { $0.orderBy = "live-carry-dispatch-orders-id" })
        let entry = CarryDispatchOrdersIDRecord(
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            nextPageToken: reply.pageInfo.nextPageToken
        )
        try await act("care-inbox-workflow", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: CarryDispatchOrdersIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "care-inbox-workflow": { try await CarryDispatchOrdersIDCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)).send(rec) },
            "care-plan": { try await CarryDispatchOrdersIDCarePlan(client: Acme_Careplans_V1_CarePlanService.Client(wrapping: mesh)).send(rec) },
            "medical-record-lifecycle": { try await CarryDispatchOrdersIDMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh)).send(rec) },
            "care-goal-lifecycle": { try await CarryDispatchOrdersIDCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
