import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateTriageDecisionID keeps of each ExplainTriageDecision response.
struct PropagateTriageDecisionIDRecord {
    var correlationID: String
    var status: String
    var message: String
    var triageID: String
}

/// Where PropagateTriageDecisionID hands each record.
protocol PropagateTriageDecisionIDWriter {
    func write(_ rec: PropagateTriageDecisionIDRecord) async throws
}

/// Hands records to acme.concessions.v1.ConcessionStandService.
struct PropagateTriageDecisionIDConcessionStand: PropagateTriageDecisionIDWriter {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func write(_ rec: PropagateTriageDecisionIDRecord) async throws {
        let request = Acme_Concessions_V1_CloneConcessionStandRequest.with {
            $0.requestID = rec.message
            $0.concessionStand.name = rec.correlationID
            $0.concessionStand.concessionStandID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cloneConcessionStand(request)
        }
    }
}

/// Passes records to acme.patients.v1.AllergySyncService.
struct PropagateTriageDecisionIDAllergySync: PropagateTriageDecisionIDWriter {
    let client: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>

    func write(_ rec: PropagateTriageDecisionIDRecord) async throws {
        _ = try await client.getAllergySyncState(.with {
            $0.allergyID = rec.message
        })
    }
}

/// Hands records to acme.prescriptions.v1.PrescriptionService.
struct PropagateTriageDecisionIDPrescription: PropagateTriageDecisionIDWriter {
    let client: Acme_Prescriptions_V1_PrescriptionService.Client<MeshTransport>

    func write(_ rec: PropagateTriageDecisionIDRecord) async throws {
        let request = Acme_Prescriptions_V1_CreatePrescriptionRequest.with {
            $0.requestID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.createPrescription(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateTriageDecisionIDLogOnly: PropagateTriageDecisionIDWriter {
    let logger = Logger(label: "acme.propagate-triage-decision-id")

    func write(_ rec: PropagateTriageDecisionIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.telehealth.v1.TriageValidationService/ExplainTriageDecision and hands what it keeps to the sink of its kind.
enum PropagateTriageDecisionID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_TriageValidationService.Client(wrapping: mesh)
        let response = try await reader.explainTriageDecision(.with { $0.triageID = "main-propagate-triage-decision-id" })
        let rec = PropagateTriageDecisionIDRecord(
            correlationID: response.result.correlationID,
            status: Kit.Text.normalize(response.result.status),
            message: response.result.message,
            triageID: response.triage.triageID
        )
        try await dispatch("prescription", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PropagateTriageDecisionIDRecord, _ mesh: MeshClient) async throws {
        var write: (PropagateTriageDecisionIDRecord) async throws -> Void = PropagateTriageDecisionIDLogOnly().write
        switch kind {
        case "concession-stand":
            write = PropagateTriageDecisionIDConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)).write
        case "allergy-sync":
            write = PropagateTriageDecisionIDAllergySync(client: Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)).write
        case "prescription":
            write = PropagateTriageDecisionIDPrescription(client: Acme_Prescriptions_V1_PrescriptionService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
