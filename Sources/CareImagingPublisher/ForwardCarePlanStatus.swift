import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardCarePlanStatus keeps of each PreviewCarePlan response.
struct ForwardCarePlanStatusRecord {
    var status: String
    var message: String
}

/// Where ForwardCarePlanStatus hands each record.
protocol ForwardCarePlanStatusWriter {
    func send(_ rec: ForwardCarePlanStatusRecord) async throws
}

/// Passes records to acme.licensing.v1.SoftwareLicenseQueryService.
struct ForwardCarePlanStatusSoftwareLicenseQuery: ForwardCarePlanStatusWriter {
    let client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client<MeshTransport>

    func send(_ rec: ForwardCarePlanStatusRecord) async throws {
        let request = Acme_Licensing_V1_SuggestSoftwareLicensesRequest.with {
            $0.page.pageToken = rec.status
            $0.filter.query = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestSoftwareLicenses(request)
        }
    }
}

/// Passes records to acme.careplans.v1.VitalValidationService.
struct ForwardCarePlanStatusVitalValidation: ForwardCarePlanStatusWriter {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func send(_ rec: ForwardCarePlanStatusRecord) async throws {
        _ = try await client.scoreVital(.with {
            $0.details.currencyCode = rec.message
            $0.vital.source = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardCarePlanStatusLogOnly: ForwardCarePlanStatusWriter {
    let logger = Logger(label: "acme.forward-care-plan-status")

    func send(_ rec: ForwardCarePlanStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.careplans.v1.CarePlanValidationService/PreviewCarePlan and hands what it keeps to the sink of its kind.
enum ForwardCarePlanStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh)
        let found = try await source.previewCarePlan(.with { $0.reason = "main-forward-care-plan-status" })
        let rec = ForwardCarePlanStatusRecord(
            status: Kit.Text.normalize(found.outcome.status),
            message: found.result.message
        )
        try await deliver("software-license-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ForwardCarePlanStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any ForwardCarePlanStatusWriter = ForwardCarePlanStatusLogOnly()
        switch kind {
        case "software-license-query":
            sink = ForwardCarePlanStatusSoftwareLicenseQuery(client: Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh))
        case "vital-validation":
            sink = ForwardCarePlanStatusVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
