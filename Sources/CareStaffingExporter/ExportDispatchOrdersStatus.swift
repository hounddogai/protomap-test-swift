import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportDispatchOrdersStatus keeps of each CountDispatchOrders response.
struct ExportDispatchOrdersStatusRecord {
    var status: String
    var correlationID: String
    var message: String
}

/// Where ExportDispatchOrdersStatus hands each record.
protocol ExportDispatchOrdersStatusSink {
    func forward(_ rec: ExportDispatchOrdersStatusRecord) async throws
}

/// Writes records to acme.authorization.v1.AccessPolicyValidationService.
struct ExportDispatchOrdersStatusAccessPolicyValidation: ExportDispatchOrdersStatusSink {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func forward(_ rec: ExportDispatchOrdersStatusRecord) async throws {
        _ = try await client.getAccessPolicyRules(.with {
            $0.accessPolicyID = rec.message
        })
    }
}

/// Hands records to acme.patients.v1.PatientCalculationService.
struct ExportDispatchOrdersStatusPatientCalculation: ExportDispatchOrdersStatusSink {
    let client: Acme_Patients_V1_PatientCalculationService.Client<MeshTransport>

    func forward(_ rec: ExportDispatchOrdersStatusRecord) async throws {
        _ = try await client.explainPatientCalculation(.with {
            $0.patientID = rec.status
            $0.reason = rec.correlationID
        })
    }
}

/// Hands records to acme.careplans.v1.VitalLifecycleService.
struct ExportDispatchOrdersStatusVitalLifecycle: ExportDispatchOrdersStatusSink {
    let client: Acme_Careplans_V1_VitalLifecycleService.Client<MeshTransport>

    func forward(_ rec: ExportDispatchOrdersStatusRecord) async throws {
        _ = try await client.reinstateVital(.with {
            $0.reason = rec.status
            $0.vitalID = rec.message
            $0.details.reasonCode = rec.correlationID
        })
    }
}

/// Reads acme.dispatch.v1.DispatchOrderQueryService/CountDispatchOrders and hands what it keeps to the sink of its kind.
enum ExportDispatchOrdersStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)
        let found = try await reader.countDispatchOrders(.with { $0.orderBy = "primary-export-dispatch-orders-status" })
        let rec = ExportDispatchOrdersStatusRecord(
            status: found.result.status,
            correlationID: found.result.correlationID,
            message: found.result.message
        )
        try await act("vital-lifecycle", rec, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: ExportDispatchOrdersStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "access-policy-validation": { try await ExportDispatchOrdersStatusAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh)).forward(rec) },
            "patient-calculation": { try await ExportDispatchOrdersStatusPatientCalculation(client: Acme_Patients_V1_PatientCalculationService.Client(wrapping: mesh)).forward(rec) },
            "vital-lifecycle": { try await ExportDispatchOrdersStatusVitalLifecycle(client: Acme_Careplans_V1_VitalLifecycleService.Client(wrapping: mesh)).forward(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
