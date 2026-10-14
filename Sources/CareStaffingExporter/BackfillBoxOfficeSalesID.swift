import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillBoxOfficeSalesID keeps of each SummarizeBoxOfficeSales response.
struct BackfillBoxOfficeSalesIDRecord {
    var reportID: String
    var timezone: String
    var message: String
}

/// Where BackfillBoxOfficeSalesID hands each record.
protocol BackfillBoxOfficeSalesIDDestination {
    func push(_ rec: BackfillBoxOfficeSalesIDRecord) async throws
}

/// Sends records to acme.careplans.v1.CareGoalLifecycleService.
struct BackfillBoxOfficeSalesIDCareGoalLifecycle: BackfillBoxOfficeSalesIDDestination {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func push(_ rec: BackfillBoxOfficeSalesIDRecord) async throws {
        _ = try await client.expireCareGoal(.with {
            $0.details.reasonCode = rec.timezone
            $0.reason = rec.reportID
        })
    }
}

/// Sends records to acme.patients.v1.MedicalRecordWorkflowService.
struct BackfillBoxOfficeSalesIDMedicalRecordWorkflow: BackfillBoxOfficeSalesIDDestination {
    let client: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>

    func push(_ rec: BackfillBoxOfficeSalesIDRecord) async throws {
        let request = Acme_Patients_V1_PauseMedicalRecordWorkflowRequest.with {
            $0.medicalRecord.number = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.pauseMedicalRecordWorkflow(request)
        }
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleQueryService/SummarizeBoxOfficeSales and hands what it keeps to the sink of its kind.
enum BackfillBoxOfficeSalesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)
        let found = try await origin.summarizeBoxOfficeSales(.with { $0.reason = "default-backfill-box-office-sales-id" })
        let rec = BackfillBoxOfficeSalesIDRecord(
            reportID: found.reportID,
            timezone: found.period.timezone,
            message: found.result.message
        )
        let sinks: [any BackfillBoxOfficeSalesIDDestination] = [
            BackfillBoxOfficeSalesIDCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
            BackfillBoxOfficeSalesIDMedicalRecordWorkflow(client: Acme_Patients_V1_MedicalRecordWorkflowService.Client(wrapping: mesh)),
        ]
        try await sinks[0].push(rec)
    }
}
