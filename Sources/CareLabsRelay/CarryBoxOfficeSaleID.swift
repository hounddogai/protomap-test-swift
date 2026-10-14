import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryBoxOfficeSaleID keeps of each DeleteBoxOfficeSale response.
struct CarryBoxOfficeSaleIDRecord {
    var correlationID: String
    var status: String
    var message: String
}

/// Where CarryBoxOfficeSaleID hands each record.
protocol CarryBoxOfficeSaleIDDestination {
    func deliver(_ rec: CarryBoxOfficeSaleIDRecord) async throws
}

/// Sends records to acme.telehealth.v1.VisitNoteApprovalService.
struct CarryBoxOfficeSaleIDVisitNoteApproval: CarryBoxOfficeSaleIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>

    func deliver(_ rec: CarryBoxOfficeSaleIDRecord) async throws {
        _ = try await client.listPendingVisitNotes(.with {
            $0.page.pageToken = rec.message
            $0.filter.query = rec.correlationID
            $0.filter.ownerID = rec.status
        })
    }
}

/// Sends records to acme.telehealth.v1.VisitNoteValidationService.
struct CarryBoxOfficeSaleIDVisitNoteValidation: CarryBoxOfficeSaleIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func deliver(_ rec: CarryBoxOfficeSaleIDRecord) async throws {
        _ = try await client.previewVisitNote(.with {
            $0.reason = rec.message
        })
    }
}

/// Writes records to acme.concessions.v1.ConcessionStandCalculationService.
struct CarryBoxOfficeSaleIDConcessionStandCalculation: CarryBoxOfficeSaleIDDestination {
    let client: Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>

    func deliver(_ rec: CarryBoxOfficeSaleIDRecord) async throws {
        _ = try await client.estimateConcessionStand(.with {
            $0.concessionStand.concessionStandID = rec.status
            $0.concessionStand.name = rec.message
        })
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleService/DeleteBoxOfficeSale and hands what it keeps to the sink of its kind.
enum CarryBoxOfficeSaleID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Boxoffice_V1_BoxOfficeSaleService.Client(wrapping: mesh)
        let found = try await upstream.deleteBoxOfficeSale(.with { $0.etag = "nightly-carry-box-office-sale-id" })
        let entry = CarryBoxOfficeSaleIDRecord(
            correlationID: found.result.correlationID,
            status: found.result.status,
            message: found.result.message
        )
        let sinks: [any CarryBoxOfficeSaleIDDestination] = [
            CarryBoxOfficeSaleIDVisitNoteApproval(client: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: mesh)),
            CarryBoxOfficeSaleIDVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)),
            CarryBoxOfficeSaleIDConcessionStandCalculation(client: Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].deliver(entry)
    }
}
