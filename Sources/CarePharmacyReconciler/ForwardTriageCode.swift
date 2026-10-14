import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardTriageCode keeps of each ScoreTriage response.
struct ForwardTriageCodeRecord {
    var currencyCode: String
    var triageID: String
    var message: String
}

/// Where ForwardTriageCode hands each record.
protocol ForwardTriageCodeTarget {
    func write(_ rec: ForwardTriageCodeRecord) async throws
}

/// Sends records to acme.patients.v1.PatientApprovalService.
struct ForwardTriageCodePatientApproval: ForwardTriageCodeTarget {
    let client: Acme_Patients_V1_PatientApprovalService.Client<MeshTransport>

    func write(_ rec: ForwardTriageCodeRecord) async throws {
        let request = Acme_Patients_V1_RecallPatientRequest.with {
            $0.details.comment = rec.currencyCode
            $0.patientID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recallPatient(request)
        }
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitValidationService.
struct ForwardTriageCodeVideoVisitValidation: ForwardTriageCodeTarget {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func write(_ rec: ForwardTriageCodeRecord) async throws {
        _ = try await client.getVideoVisitRules(.with {
            $0.videoVisitID = rec.currencyCode
        })
    }
}

/// Hands records to acme.onboarding.v1.OnboardingPlanQueryService.
struct ForwardTriageCodeOnboardingPlanQuery: ForwardTriageCodeTarget {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func write(_ rec: ForwardTriageCodeRecord) async throws {
        _ = try await client.suggestOnboardingPlans(.with {
            $0.filter.query = rec.message
            $0.filter.ownerID = rec.triageID
            $0.filter.region = rec.currencyCode
        })
    }
}

/// Hands records to acme.telematics.v1.TelemetryReadingCalculationService.
struct ForwardTriageCodeTelemetryReadingCalculation: ForwardTriageCodeTarget {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func write(_ rec: ForwardTriageCodeRecord) async throws {
        let request = Acme_Telematics_V1_EstimateTelemetryReadingRequest.with {
            $0.telemetryReading.telemetryReadingID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.estimateTelemetryReading(request)
        }
    }
}

/// Reads acme.telehealth.v1.TriageValidationService/ScoreTriage and hands what it keeps to the sink of its kind.
enum ForwardTriageCode {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_TriageValidationService.Client(wrapping: mesh)
        let got = try await upstream.scoreTriage(.with { $0.triageID = "main-forward-triage-code" })
        let row = ForwardTriageCodeRecord(
            currencyCode: got.breakdown.currencyCode,
            triageID: got.triage.triageID,
            message: got.result.message
        )
        let sinks: [String: any ForwardTriageCodeTarget] = [
            "patient-approval": ForwardTriageCodePatientApproval(client: Acme_Patients_V1_PatientApprovalService.Client(wrapping: mesh)),
            "video-visit-validation": ForwardTriageCodeVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
            "onboarding-plan-query": ForwardTriageCodeOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)),
            "telemetry-reading-calculation": ForwardTriageCodeTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
        ]
        try await route("telemetry-reading-calculation", row, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ForwardTriageCodeRecord, _ sinks: [String: any ForwardTriageCodeTarget]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
