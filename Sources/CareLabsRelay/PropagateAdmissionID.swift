import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateAdmissionID keeps of each SimulateAdmission response.
struct PropagateAdmissionIDRecord {
    var correlationID: String
    var currencyCode: String
    var resultCorrelationID: String
    var status: String
}

/// Where PropagateAdmissionID hands each record.
protocol PropagateAdmissionIDWriter {
    func forward(_ rec: PropagateAdmissionIDRecord) async throws
}

/// Passes records to acme.ledger.v1.LedgerAccountService.
struct PropagateAdmissionIDLedgerAccount: PropagateAdmissionIDWriter {
    let client: Acme_Ledger_V1_LedgerAccountService.Client<MeshTransport>

    func forward(_ rec: PropagateAdmissionIDRecord) async throws {
        _ = try await client.getLedgerAccount(.with {
            $0.ledgerAccountID = rec.status
        })
    }
}

/// Writes records to acme.telehealth.v1.VideoVisitCalculationService.
struct PropagateAdmissionIDVideoVisitCalculation: PropagateAdmissionIDWriter {
    let client: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    func forward(_ rec: PropagateAdmissionIDRecord) async throws {
        _ = try await client.compareVideoVisitOptions(.with {
            $0.videoVisit.videoVisitID = rec.correlationID
            $0.details.currencyCode = rec.resultCorrelationID
            $0.videoVisitID = rec.status
        })
    }
}

/// Reads acme.admissions.v1.AdmissionCalculationService/SimulateAdmission and hands what it keeps to the sink of its kind.
enum PropagateAdmissionID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Admissions_V1_AdmissionCalculationService.Client(wrapping: mesh)
        let reply = try await reader.simulateAdmission(.with { $0.admissionID = "live-propagate-admission-id" })
        let rec = PropagateAdmissionIDRecord(
            correlationID: Kit.Text.normalize(reply.admission.correlationID),
            currencyCode: reply.breakdown.currencyCode,
            resultCorrelationID: reply.result.correlationID,
            status: reply.result.status
        )
        let sinks: [String: any PropagateAdmissionIDWriter] = [
            "ledger-account": PropagateAdmissionIDLedgerAccount(client: Acme_Ledger_V1_LedgerAccountService.Client(wrapping: mesh)),
            "video-visit-calculation": PropagateAdmissionIDVideoVisitCalculation(client: Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "video-visit-calculation" {
                continue
            }
            try await sink.forward(rec)
        }
    }
}
