@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureManifestTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFallbackClosureManifest("code-867", label: "label-122")
        #expect(item.status == Referrals.FallbackClosureManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newFallbackClosureManifest("code-867", label: "label-122")
        try item.moveTo(Referrals.FallbackClosureManifestStatus.approved)
        #expect(item.status == Referrals.FallbackClosureManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFallbackClosureManifest("code-867", label: "label-122")
        item.status = Referrals.FallbackClosureManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackClosureManifestStatus.proposed) }
    }
}
