@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolManifestTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newRegionalCareProtocolManifest("code-536", label: "label-316")
        #expect(item.status == ClinicalOps.RegionalCareProtocolManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newRegionalCareProtocolManifest("code-536", label: "label-316")
        try item.moveTo(ClinicalOps.RegionalCareProtocolManifestStatus.revoked)
        #expect(item.status == ClinicalOps.RegionalCareProtocolManifestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newRegionalCareProtocolManifest("code-536", label: "label-316")
        item.status = ClinicalOps.RegionalCareProtocolManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalCareProtocolManifestStatus.requested) }
    }
}
