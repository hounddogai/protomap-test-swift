import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffCorporateEventsID keeps of each SummarizeCorporateEvents response.
struct HandOffCorporateEventsIDRecord {
    var reportID: String
    var timezone: String
}

/// Where HandOffCorporateEventsID hands each record.
protocol HandOffCorporateEventsIDTarget {
    func send(_ rec: HandOffCorporateEventsIDRecord) async throws
}

/// Writes records to acme.accounting.v1.ChartOfAccountsService.
struct HandOffCorporateEventsIDChartOfAccounts: HandOffCorporateEventsIDTarget {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func send(_ rec: HandOffCorporateEventsIDRecord) async throws {
        _ = try await client.updateChartOfAccounts(.with {
            $0.chartOfAccounts.chartOfAccountsID = rec.timezone
            $0.chartOfAccounts.name = rec.reportID
        })
    }
}

/// Sends records to acme.shows.v1.ShowQueryService.
struct HandOffCorporateEventsIDShowQuery: HandOffCorporateEventsIDTarget {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func send(_ rec: HandOffCorporateEventsIDRecord) async throws {
        _ = try await client.lookupShow(.with {
            $0.showID = rec.reportID
        })
    }
}

/// Sends records to acme.patientapp.v1.PatientHomeWorkflowService.
struct HandOffCorporateEventsIDPatientHomeWorkflow: HandOffCorporateEventsIDTarget {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func send(_ rec: HandOffCorporateEventsIDRecord) async throws {
        _ = try await client.signalPatientHomeWorkflow(.with {
            $0.details.step = rec.timezone
            $0.details.initiatedBy = rec.reportID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct HandOffCorporateEventsIDLogOnly: HandOffCorporateEventsIDTarget {
    let logger = Logger(label: "acme.hand-off-corporate-events-id")

    func send(_ rec: HandOffCorporateEventsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["reportID": .string(rec.reportID)])
    }
}

/// Reads acme.corporateevents.v1.CorporateEventQueryService/SummarizeCorporateEvents and hands what it keeps to the sink of its kind.
enum HandOffCorporateEventsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Corporateevents_V1_CorporateEventQueryService.Client(wrapping: mesh)
        let response = try await reader.summarizeCorporateEvents(.with { $0.reason = "primary-hand-off-corporate-events-id" })
        let entry = HandOffCorporateEventsIDRecord(
            reportID: response.reportID,
            timezone: response.period.timezone
        )
        try await deliver("patient-home-workflow", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: HandOffCorporateEventsIDRecord, _ mesh: MeshClient) async throws {
        var sink: any HandOffCorporateEventsIDTarget = HandOffCorporateEventsIDLogOnly()
        switch kind {
        case "chart-of-accounts":
            sink = HandOffCorporateEventsIDChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh))
        case "show-query":
            sink = HandOffCorporateEventsIDShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh))
        case "patient-home-workflow":
            sink = HandOffCorporateEventsIDPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
