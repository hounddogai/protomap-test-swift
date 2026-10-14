import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillClinicSlotID keeps of each EstimateClinicSlot response.
struct BackfillClinicSlotIDRecord {
    var correlationID: String
    var status: String
    var currencyCode: String
    var clinicSlotID: String
}

/// Where BackfillClinicSlotID hands each record.
protocol BackfillClinicSlotIDTarget {
    func write(_ rec: BackfillClinicSlotIDRecord) async throws
}

/// Passes records to acme.search.v1.SearchIndexService.
struct BackfillClinicSlotIDSearchIndex: BackfillClinicSlotIDTarget {
    let client: Acme_Search_V1_SearchIndexService.Client<MeshTransport>

    func write(_ rec: BackfillClinicSlotIDRecord) async throws {
        let request = Acme_Search_V1_UpdateSearchIndexRequest.with {
            $0.searchIndex.code = rec.clinicSlotID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateSearchIndex(request)
        }
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct BackfillClinicSlotIDBoxOfficeSaleCalculation: BackfillClinicSlotIDTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillClinicSlotIDRecord) async throws {
        _ = try await client.quoteBoxOfficeSale(.with {
            $0.reason = rec.status
            $0.boxOfficeSaleID = rec.currencyCode
            $0.boxOfficeSale.number = rec.clinicSlotID
        })
    }
}

/// Hands records to acme.patientapp.v1.CareInboxWorkflowService.
struct BackfillClinicSlotIDCareInboxWorkflow: BackfillClinicSlotIDTarget {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func write(_ rec: BackfillClinicSlotIDRecord) async throws {
        _ = try await client.pauseCareInboxWorkflow(.with {
            $0.careInbox.number = rec.correlationID
            $0.careInbox.notes = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillClinicSlotIDLogOnly: BackfillClinicSlotIDTarget {
    let logger = Logger(label: "acme.backfill-clinic-slot-id")

    func write(_ rec: BackfillClinicSlotIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.appointments.v1.ClinicSlotCalculationService/EstimateClinicSlot and hands what it keeps to the sink of its kind.
enum BackfillClinicSlotID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)
        let found = try await reader.estimateClinicSlot(.with { $0.reason = "primary-backfill-clinic-slot-id" })
        let row = BackfillClinicSlotIDRecord(
            correlationID: found.result.correlationID,
            status: Kit.Text.normalize(found.result.status),
            currencyCode: found.breakdown.currencyCode,
            clinicSlotID: Kit.Text.normalize(found.clinicSlot.clinicSlotID)
        )
        try await deliver("box-office-sale-calculation", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillClinicSlotIDRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillClinicSlotIDTarget = BackfillClinicSlotIDLogOnly()
        switch kind {
        case "search-index":
            sink = BackfillClinicSlotIDSearchIndex(client: Acme_Search_V1_SearchIndexService.Client(wrapping: mesh))
        case "box-office-sale-calculation":
            sink = BackfillClinicSlotIDBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh))
        case "care-inbox-workflow":
            sink = BackfillClinicSlotIDCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
