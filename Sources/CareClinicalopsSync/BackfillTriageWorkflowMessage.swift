import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillTriageWorkflowMessage keeps of each RetryTriageWorkflow response.
struct BackfillTriageWorkflowMessageRecord {
    var message: String
    var subject: String
    var correlationID: String
}

/// Where BackfillTriageWorkflowMessage hands each record.
protocol BackfillTriageWorkflowMessageSink {
    func write(_ rec: BackfillTriageWorkflowMessageRecord) async throws
}

/// Hands records to acme.prescriptions.v1.RefillCalculationService.
struct BackfillTriageWorkflowMessageRefillCalculation: BackfillTriageWorkflowMessageSink {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillTriageWorkflowMessageRecord) async throws {
        _ = try await client.calculateRefill(.with {
            $0.reason = rec.subject
            $0.refill.refillID = rec.correlationID
        })
    }
}

/// Writes records to acme.careplans.v1.VitalValidationService.
struct BackfillTriageWorkflowMessageVitalValidation: BackfillTriageWorkflowMessageSink {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func write(_ rec: BackfillTriageWorkflowMessageRecord) async throws {
        _ = try await client.normalizeVital(.with {
            $0.vital.correlationID = rec.message
            $0.vital.vitalID = rec.subject
        })
    }
}

/// Passes records to acme.telehealth.v1.TriageLifecycleService.
struct BackfillTriageWorkflowMessageTriageLifecycle: BackfillTriageWorkflowMessageSink {
    let client: Acme_Telehealth_V1_TriageLifecycleService.Client<MeshTransport>

    func write(_ rec: BackfillTriageWorkflowMessageRecord) async throws {
        _ = try await client.reinstateTriage(.with {
            $0.reason = rec.message
            $0.details.reasonCode = rec.correlationID
        })
    }
}

/// Reads acme.telehealth.v1.TriageWorkflowService/RetryTriageWorkflow and hands what it keeps to the sink of its kind.
enum BackfillTriageWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)
        let reply = try await source.retryTriageWorkflow(.with { $0.reason = "main-backfill-triage-workflow-message" })
        let entry = BackfillTriageWorkflowMessageRecord(
            message: reply.outcome.message,
            subject: Kit.Text.normalize(reply.triage.subject),
            correlationID: reply.result.correlationID
        )
        let sinks: [String: any BackfillTriageWorkflowMessageSink] = [
            "refill-calculation": BackfillTriageWorkflowMessageRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh)),
            "vital-validation": BackfillTriageWorkflowMessageVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
            "triage-lifecycle": BackfillTriageWorkflowMessageTriageLifecycle(client: Acme_Telehealth_V1_TriageLifecycleService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "triage-lifecycle" {
                continue
            }
            try await sink.write(entry)
        }
    }
}
