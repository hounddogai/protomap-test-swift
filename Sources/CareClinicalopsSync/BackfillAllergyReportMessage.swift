import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillAllergyReportMessage keeps of each DeleteAllergyReport response.
struct BackfillAllergyReportMessageRecord {
    var message: String
    var correlationID: String
}

/// Where BackfillAllergyReportMessage hands each record.
protocol BackfillAllergyReportMessageTarget {
    func forward(_ rec: BackfillAllergyReportMessageRecord) async throws
}

/// Passes records to acme.careplans.v1.CarePlanValidationService.
struct BackfillAllergyReportMessageCarePlanValidation: BackfillAllergyReportMessageTarget {
    let client: Acme_Careplans_V1_CarePlanValidationService.Client<MeshTransport>

    func forward(_ rec: BackfillAllergyReportMessageRecord) async throws {
        _ = try await client.lintCarePlans(.with {
            $0.carePlanID = rec.message
        })
    }
}

/// Passes records to acme.onboarding.v1.OnboardingPlanQueryService.
struct BackfillAllergyReportMessageOnboardingPlanQuery: BackfillAllergyReportMessageTarget {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func forward(_ rec: BackfillAllergyReportMessageRecord) async throws {
        _ = try await client.lookupOnboardingPlan(.with {
            $0.onboardingPlanID = rec.message
        })
    }
}

/// Hands records to acme.patients.v1.PatientLifecycleService.
struct BackfillAllergyReportMessagePatientLifecycle: BackfillAllergyReportMessageTarget {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func forward(_ rec: BackfillAllergyReportMessageRecord) async throws {
        _ = try await client.schedulePatientExpiry(.with {
            $0.reason = rec.correlationID
            $0.patient.patientID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillAllergyReportMessageLogOnly: BackfillAllergyReportMessageTarget {
    let logger = Logger(label: "acme.backfill-allergy-report-message")

    func forward(_ rec: BackfillAllergyReportMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.patients.v1.AllergyReportingService/DeleteAllergyReport and hands what it keeps to the sink of its kind.
enum BackfillAllergyReportMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Patients_V1_AllergyReportingService.Client(wrapping: mesh)
        let reply = try await reader.deleteAllergyReport(.with { $0.etag = "primary-backfill-allergy-report-message" })
        let entry = BackfillAllergyReportMessageRecord(
            message: Kit.Text.normalize(reply.result.message),
            correlationID: reply.result.correlationID
        )
        try await deliver("patient-lifecycle", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillAllergyReportMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillAllergyReportMessageTarget = BackfillAllergyReportMessageLogOnly()
        switch kind {
        case "care-plan-validation":
            sink = BackfillAllergyReportMessageCarePlanValidation(client: Acme_Careplans_V1_CarePlanValidationService.Client(wrapping: mesh))
        case "onboarding-plan-query":
            sink = BackfillAllergyReportMessageOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh))
        case "patient-lifecycle":
            sink = BackfillAllergyReportMessagePatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
