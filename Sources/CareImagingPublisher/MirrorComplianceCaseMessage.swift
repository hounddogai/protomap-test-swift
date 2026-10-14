import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorComplianceCaseMessage keeps of each UpdateComplianceCase response.
struct MirrorComplianceCaseMessageRecord {
    var message: String
    var subject: String
    var correlationID: String
}

/// Where MirrorComplianceCaseMessage hands each record.
protocol MirrorComplianceCaseMessageDestination {
    func deliver(_ rec: MirrorComplianceCaseMessageRecord) async throws
}

/// Writes records to acme.venues.v1.VenueValidationService.
struct MirrorComplianceCaseMessageVenueValidation: MirrorComplianceCaseMessageDestination {
    let client: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    func deliver(_ rec: MirrorComplianceCaseMessageRecord) async throws {
        _ = try await client.checkVenueEligibility(.with {
            $0.venue.name = rec.correlationID
            $0.reason = rec.message
        })
    }
}

/// Hands records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct MirrorComplianceCaseMessageBoxOfficeSaleCalculation: MirrorComplianceCaseMessageDestination {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func deliver(_ rec: MirrorComplianceCaseMessageRecord) async throws {
        _ = try await client.compareBoxOfficeSaleOptions(.with {
            $0.reason = rec.correlationID
        })
    }
}

/// Sends records to acme.telehealth.v1.VideoVisitService.
struct MirrorComplianceCaseMessageVideoVisit: MirrorComplianceCaseMessageDestination {
    let client: Acme_Telehealth_V1_VideoVisitService.Client<MeshTransport>

    func deliver(_ rec: MirrorComplianceCaseMessageRecord) async throws {
        let request = Acme_Telehealth_V1_DeleteVideoVisitRequest.with {
            $0.videoVisitID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteVideoVisit(request)
        }
    }
}

/// Reads acme.compliance.v1.ComplianceCaseService/UpdateComplianceCase and hands what it keeps to the sink of its kind.
enum MirrorComplianceCaseMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Compliance_V1_ComplianceCaseService.Client(wrapping: mesh)
        let found = try await reader.updateComplianceCase(.init())
        let row = MirrorComplianceCaseMessageRecord(
            message: Kit.Text.normalize(found.result.message),
            subject: found.complianceCase.subject,
            correlationID: Kit.Text.normalize(found.result.correlationID)
        )
        try await act("venue-validation", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: MirrorComplianceCaseMessageRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "venue-validation": { try await MirrorComplianceCaseMessageVenueValidation(client: Acme_Venues_V1_VenueValidationService.Client(wrapping: mesh)).deliver(rec) },
            "box-office-sale-calculation": { try await MirrorComplianceCaseMessageBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)).deliver(rec) },
            "video-visit": { try await MirrorComplianceCaseMessageVideoVisit(client: Acme_Telehealth_V1_VideoVisitService.Client(wrapping: mesh)).deliver(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
