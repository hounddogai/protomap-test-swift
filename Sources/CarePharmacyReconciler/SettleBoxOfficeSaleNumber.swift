import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleBoxOfficeSaleNumber keeps of each LookupBoxOfficeSale response.
struct SettleBoxOfficeSaleNumberRecord {
    var number: String
    var status: String
    var correlationID: String
}

/// Where SettleBoxOfficeSaleNumber hands each record.
protocol SettleBoxOfficeSaleNumberSink {
    func write(_ rec: SettleBoxOfficeSaleNumberRecord) async throws
}

/// Hands records to acme.shows.v1.ShowQueryService.
struct SettleBoxOfficeSaleNumberShowQuery: SettleBoxOfficeSaleNumberSink {
    let client: Acme_Shows_V1_ShowQueryService.Client<MeshTransport>

    func write(_ rec: SettleBoxOfficeSaleNumberRecord) async throws {
        _ = try await client.browseShows(.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.number
        })
    }
}

/// Passes records to acme.admissions.v1.AdmissionCalculationService.
struct SettleBoxOfficeSaleNumberAdmissionCalculation: SettleBoxOfficeSaleNumberSink {
    let client: Acme_Admissions_V1_AdmissionCalculationService.Client<MeshTransport>

    func write(_ rec: SettleBoxOfficeSaleNumberRecord) async throws {
        _ = try await client.estimateAdmission(.with {
            $0.admissionID = rec.status
            $0.reason = rec.correlationID
            $0.admission.correlationID = rec.number
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleBoxOfficeSaleNumberLogOnly: SettleBoxOfficeSaleNumberSink {
    let logger = Logger(label: "acme.settle-box-office-sale-number")

    func write(_ rec: SettleBoxOfficeSaleNumberRecord) async throws {
        logger.info("No sink for record", metadata: ["number": .string(rec.number)])
    }
}

/// Reads acme.boxoffice.v1.BoxOfficeSaleQueryService/LookupBoxOfficeSale and hands what it keeps to the sink of its kind.
enum SettleBoxOfficeSaleNumber {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)
        let response = try await upstream.lookupBoxOfficeSale(.with { $0.boxOfficeSaleID = "nightly-settle-box-office-sale-number" })
        let record = SettleBoxOfficeSaleNumberRecord(
            number: response.boxOfficeSale.number,
            status: response.result.status,
            correlationID: response.result.correlationID
        )
        try await deliver("admission-calculation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SettleBoxOfficeSaleNumberRecord, _ mesh: MeshClient) async throws {
        var sink: any SettleBoxOfficeSaleNumberSink = SettleBoxOfficeSaleNumberLogOnly()
        switch kind {
        case "show-query":
            sink = SettleBoxOfficeSaleNumberShowQuery(client: Acme_Shows_V1_ShowQueryService.Client(wrapping: mesh))
        case "admission-calculation":
            sink = SettleBoxOfficeSaleNumberAdmissionCalculation(client: Acme_Admissions_V1_AdmissionCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
