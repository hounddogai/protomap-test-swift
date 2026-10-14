@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingManifestTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newFallbackRoundingManifest("code-996", label: "label-350")
        #expect(item.status == ClinicalOps.FallbackRoundingManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newFallbackRoundingManifest("code-996", label: "label-350")
        try item.moveTo(ClinicalOps.FallbackRoundingManifestStatus.revoked)
        #expect(item.status == ClinicalOps.FallbackRoundingManifestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newFallbackRoundingManifest("code-996", label: "label-350")
        item.status = ClinicalOps.FallbackRoundingManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackRoundingManifestStatus.requested) }
    }
}
