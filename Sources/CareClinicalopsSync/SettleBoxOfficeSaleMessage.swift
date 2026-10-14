import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleBoxOfficeSaleMessage keeps of each CreateBoxOfficeSale response.
struct SettleBoxOfficeSaleMessageRecord {
    var message: String
    var number: String
    var correlationID: String
    var status: String
}

/// Where SettleBoxOfficeSaleMessage hands each record.
protocol SettleBoxOfficeSaleMessageSink {
    func write(_ rec: SettleBoxOfficeSaleMessageRecord) async throws
}

/// Hands records to acme.careplans.v1.VitalWorkflowService.
struct SettleBoxOfficeSaleMessageVitalWorkflow: SettleBoxOfficeSaleMessageSink {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func write(_ rec: SettleBoxOfficeSaleMessageRecord) async throws {
        let request = Acme_Careplans_V1_PauseVitalWorkflowRequest.with {
            $0.details.step = rec.correlationID
            $0.vitalID = rec.number
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.pauseVitalWorkflow(request)
        }
    }
}

/// Passes records to acme.careplans.v1.CarePlanCalculationService.
struct SettleBoxOfficeSaleMessageCarePlanCalculation: SettleBoxOfficeSaleMessageSink {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func write(_ rec: SettleBoxOfficeSaleMessageRecord) async throws {
        _ = try await client.calculateCarePlan(.with {
            $0.carePlanID = rec.message
            $0.details.currencyCode = rec.correlationID
            $0.carePlan.number = rec.status
        })
    }
}

/// Passes records to acme.budgeting.v1.BudgetQueryService.
struct SettleBoxOfficeSaleMessageBudgetQuery: SettleBoxOfficeSaleMessageSink {
    let client: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>

    func write(_ rec: SettleBoxOfficeSaleMessageRecord) async throws {
        _ = try await client.summarizeBudgets(.with {
            $0.details.cron = rec.status
            $0.details.format = rec.message
            $0.reason = rec.number
        })
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleService/CreateBoxOfficeSale and hands what it keeps to the sink of its kind.
enum SettleBoxOfficeSaleMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)
        let got = try await reader.createBoxOfficeSale(.with { $0.requestID = "live-settle-box-office-sale-message" })
        let row = SettleBoxOfficeSaleMessageRecord(
            message: got.result.message,
            number: got.boxOfficeSale.number,
            correlationID: Kit.Text.normalize(got.result.correlationID),
            status: Kit.Text.normalize(got.result.status)
        )
        let sinks: [String: any SettleBoxOfficeSaleMessageSink] = [
            "vital-workflow": SettleBoxOfficeSaleMessageVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)),
            "care-plan-calculation": SettleBoxOfficeSaleMessageCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)),
            "budget-query": SettleBoxOfficeSaleMessageBudgetQuery(client: Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "care-plan-calculation" {
                continue
            }
            try await sink.write(row)
        }
    }
}
