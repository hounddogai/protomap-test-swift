@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpManifestTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newTieredFollowUpManifest("code-588", label: "label-767")
        #expect(item.status == Referrals.TieredFollowUpManifestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newTieredFollowUpManifest("code-588", label: "label-767")
        try item.moveTo(Referrals.TieredFollowUpManifestStatus.ready)
        #expect(item.status == Referrals.TieredFollowUpManifestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newTieredFollowUpManifest("code-588", label: "label-767")
        item.status = Referrals.TieredFollowUpManifestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpManifestStatus.idle) }
    }
}
