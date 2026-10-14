import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncConfigSetID keeps of each UpdateConfigSet response.
struct SyncConfigSetIDRecord {
    var configSetID: String
    var correlationID: String
    var status: String
}

/// Where SyncConfigSetID hands each record.
protocol SyncConfigSetIDDestination {
    func apply(_ rec: SyncConfigSetIDRecord) async throws
}

/// Sends records to acme.careplans.v1.CarePlanWorkflowService.
struct SyncConfigSetIDCarePlanWorkflow: SyncConfigSetIDDestination {
    let client: Acme_Careplans_V1_CarePlanWorkflowService.Client<MeshTransport>

    func apply(_ rec: SyncConfigSetIDRecord) async throws {
        let request = Acme_Careplans_V1_StartCarePlanWorkflowRequest.with {
            $0.carePlan.carePlanID = rec.correlationID
            $0.carePlan.number = rec.configSetID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.startCarePlanWorkflow(request)
        }
    }
}

/// Hands records to acme.appointments.v1.ClinicSlotApprovalService.
struct SyncConfigSetIDClinicSlotApproval: SyncConfigSetIDDestination {
    let client: Acme_Appointments_V1_ClinicSlotApprovalService.Client<MeshTransport>

    func apply(_ rec: SyncConfigSetIDRecord) async throws {
        _ = try await client.listPendingClinicSlots(.with {
            $0.page.pageToken = rec.correlationID
            $0.orderBy = rec.configSetID
            $0.filter.region = rec.status
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordCalculationService.
struct SyncConfigSetIDMedicalRecordCalculation: SyncConfigSetIDDestination {
    let client: Acme_Patients_V1_MedicalRecordCalculationService.Client<MeshTransport>

    func apply(_ rec: SyncConfigSetIDRecord) async throws {
        let request = Acme_Patients_V1_QuoteMedicalRecordRequest.with {
            $0.medicalRecord.notes = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteMedicalRecord(request)
        }
    }
}

/// Reads acme.configuration.v1.ConfigSetService/UpdateConfigSet and hands what it keeps to the sink of its kind.
enum SyncConfigSetID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Configuration_V1_ConfigSetService.Client(wrapping: mesh)
        let response = try await origin.updateConfigSet(.init())
        let entry = SyncConfigSetIDRecord(
            configSetID: response.configSet.configSetID,
            correlationID: Kit.Text.normalize(response.result.correlationID),
            status: response.result.status
        )
        let sinks: [any SyncConfigSetIDDestination] = [
            SyncConfigSetIDCarePlanWorkflow(client: Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: mesh)),
            SyncConfigSetIDClinicSlotApproval(client: Acme_Appointments_V1_ClinicSlotApprovalService.Client(wrapping: mesh)),
            SyncConfigSetIDMedicalRecordCalculation(client: Acme_Patients_V1_MedicalRecordCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[2].apply(entry)
    }
}
