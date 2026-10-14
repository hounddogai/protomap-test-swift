import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillAllergiesKind keeps of each RecalculateAllergies response.
struct BackfillAllergiesKindRecord {
    var kind: String
    var allergyID: String
}

/// Where BackfillAllergiesKind hands each record.
protocol BackfillAllergiesKindTarget {
    func write(_ rec: BackfillAllergiesKindRecord) async throws
}

/// Passes records to acme.patients.v1.PatientLifecycleService.
struct BackfillAllergiesKindPatientLifecycle: BackfillAllergiesKindTarget {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func write(_ rec: BackfillAllergiesKindRecord) async throws {
        _ = try await client.suspendPatient(.with {
            $0.details.reasonCode = rec.kind
        })
    }
}

/// Hands records to acme.venues.v1.VenueValidationService.
struct BackfillAllergiesKindVenueValidation: BackfillAllergiesKindTarget {
    let client: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    func write(_ rec: BackfillAllergiesKindRecord) async throws {
        _ = try await client.scoreVenue(.with {
            $0.venue.name = rec.allergyID
        })
    }
}

/// Writes records to acme.fraud.v1.RiskAssessmentService.
struct BackfillAllergiesKindRiskAssessment: BackfillAllergiesKindTarget {
    let client: Acme_Fraud_V1_RiskAssessmentService.Client<MeshTransport>

    func write(_ rec: BackfillAllergiesKindRecord) async throws {
        _ = try await client.searchRiskAssessments(.with {
            $0.orderBy = rec.kind
            $0.page.pageToken = rec.allergyID
        })
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitService.
struct BackfillAllergiesKindVideoVisit: BackfillAllergiesKindTarget {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func write(_ rec: BackfillAllergiesKindRecord) async throws {
        let request = Acme_Telehealth_V1_UpdateVideoVisitRequest.with {
            $0.videoVisit.title = rec.allergyID
            $0.videoVisit.videoVisitID = rec.kind
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.updateVideoVisit(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillAllergiesKindLogOnly: BackfillAllergiesKindTarget {
    let logger = Logger(label: "acme.backfill-allergies-kind")

    func write(_ rec: BackfillAllergiesKindRecord) async throws {
        logger.info("No sink for record", metadata: ["kind": .string(rec.kind)])
    }
}

/// Reads acme.patients.v1.AllergyCalculationService/RecalculateAllergies and hands what it keeps to the sink of its kind.
enum BackfillAllergiesKind {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)
        let reply = try await upstream.recalculateAllergies(.with { $0.allergyID = "default-backfill-allergies-kind" })
        let rec = BackfillAllergiesKindRecord(
            kind: reply.allergy.kind,
            allergyID: reply.allergy.allergyID
        )
        try await deliver("risk-assessment", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillAllergiesKindRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillAllergiesKindTarget = BackfillAllergiesKindLogOnly()
        switch kind {
        case "patient-lifecycle":
            sink = BackfillAllergiesKindPatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh))
        case "venue-validation":
            sink = BackfillAllergiesKindVenueValidation(client: Acme_Venues_V1_VenueValidationService.Client(wrapping: mesh))
        case "risk-assessment":
            sink = BackfillAllergiesKindRiskAssessment(client: Acme_Fraud_V1_RiskAssessmentService.Client(wrapping: mesh))
        case "video-visit":
            sink = BackfillAllergiesKindVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
