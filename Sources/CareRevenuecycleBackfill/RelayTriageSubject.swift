import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayTriageSubject keeps of each QuoteTriage response.
struct RelayTriageSubjectRecord {
    var subject: String
    var message: String
}

/// Where RelayTriageSubject hands each record.
protocol RelayTriageSubjectSink {
    func write(_ rec: RelayTriageSubjectRecord) async throws
}

/// Passes records to acme.venues.v1.VenueValidationService.
struct RelayTriageSubjectVenueValidation: RelayTriageSubjectSink {
    let client: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    func write(_ rec: RelayTriageSubjectRecord) async throws {
        _ = try await client.previewVenue(.with {
            $0.reason = rec.message
            $0.venue.code = rec.subject
        })
    }
}

/// Sends records to acme.patients.v1.AllergyApprovalService.
struct RelayTriageSubjectAllergyApproval: RelayTriageSubjectSink {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func write(_ rec: RelayTriageSubjectRecord) async throws {
        _ = try await client.approveAllergy(.with {
            $0.allergy.correlationID = rec.subject
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayTriageSubjectLogOnly: RelayTriageSubjectSink {
    let logger = Logger(label: "acme.relay-triage-subject")

    func write(_ rec: RelayTriageSubjectRecord) async throws {
        logger.info("No sink for record", metadata: ["subject": .string(rec.subject)])
    }
}

/// Reads acme.telehealth.v1.TriageCalculationService/QuoteTriage and hands what it keeps to the sink of its kind.
enum RelayTriageSubject {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: mesh)
        let found = try await origin.quoteTriage(.with { $0.reason = "nightly-relay-triage-subject" })
        let row = RelayTriageSubjectRecord(
            subject: found.triage.subject,
            message: found.result.message
        )
        try await deliver("venue-validation", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RelayTriageSubjectRecord, _ mesh: MeshClient) async throws {
        var sink: any RelayTriageSubjectSink = RelayTriageSubjectLogOnly()
        switch kind {
        case "venue-validation":
            sink = RelayTriageSubjectVenueValidation(client: Acme_Venues_V1_VenueValidationService.Client(wrapping: mesh))
        case "allergy-approval":
            sink = RelayTriageSubjectAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
