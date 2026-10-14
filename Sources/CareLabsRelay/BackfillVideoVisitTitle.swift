import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillVideoVisitTitle keeps of each ScoreVideoVisit response.
struct BackfillVideoVisitTitleRecord {
    var title: String
    var videoVisitID: String
}

/// Where BackfillVideoVisitTitle hands each record.
protocol BackfillVideoVisitTitleTarget {
    func push(_ rec: BackfillVideoVisitTitleRecord) async throws
}

/// Sends records to acme.patientapp.v1.CareInboxNotificationService.
struct BackfillVideoVisitTitleCareInboxNotification: BackfillVideoVisitTitleTarget {
    let client: Acme_Patientapp_V1_CareInboxNotificationService.Client<MeshTransport>

    func push(_ rec: BackfillVideoVisitTitleRecord) async throws {
        let request = Acme_Patientapp_V1_NotifyCareInboxWatchersRequest.with {
            $0.reason = rec.title
            $0.careInboxID = rec.videoVisitID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.notifyCareInboxWatchers(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionValidationService.
struct BackfillVideoVisitTitlePrescriptionValidation: BackfillVideoVisitTitleTarget {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func push(_ rec: BackfillVideoVisitTitleRecord) async throws {
        let request = Acme_Prescriptions_V1_ExplainPrescriptionDecisionRequest.with {
            $0.prescriptionID = rec.videoVisitID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.explainPrescriptionDecision(request)
        }
    }
}

/// Passes records to acme.authorization.v1.AccessPolicyValidationService.
struct BackfillVideoVisitTitleAccessPolicyValidation: BackfillVideoVisitTitleTarget {
    let client: Acme_Authorization_V1_AccessPolicyValidationService.Client<MeshTransport>

    func push(_ rec: BackfillVideoVisitTitleRecord) async throws {
        let request = Acme_Authorization_V1_CheckAccessPolicyEligibilityRequest.with {
            $0.accessPolicy.name = rec.title
            $0.accessPolicy.description_p = rec.videoVisitID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.checkAccessPolicyEligibility(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillVideoVisitTitleLogOnly: BackfillVideoVisitTitleTarget {
    let logger = Logger(label: "acme.backfill-video-visit-title")

    func push(_ rec: BackfillVideoVisitTitleRecord) async throws {
        logger.info("No sink for record", metadata: ["title": .string(rec.title)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitValidationService/ScoreVideoVisit and hands what it keeps to the sink of its kind.
enum BackfillVideoVisitTitle {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)
        let response = try await origin.scoreVideoVisit(.with { $0.videoVisitID = "live-backfill-video-visit-title" })
        let rec = BackfillVideoVisitTitleRecord(
            title: Kit.Text.normalize(response.videoVisit.title),
            videoVisitID: response.videoVisit.videoVisitID
        )
        try await deliver("prescription-validation", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillVideoVisitTitleRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillVideoVisitTitleTarget = BackfillVideoVisitTitleLogOnly()
        switch kind {
        case "care-inbox-notification":
            sink = BackfillVideoVisitTitleCareInboxNotification(client: Acme_Patientapp_V1_CareInboxNotificationService.Client(wrapping: mesh))
        case "prescription-validation":
            sink = BackfillVideoVisitTitlePrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh))
        case "access-policy-validation":
            sink = BackfillVideoVisitTitleAccessPolicyValidation(client: Acme_Authorization_V1_AccessPolicyValidationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
