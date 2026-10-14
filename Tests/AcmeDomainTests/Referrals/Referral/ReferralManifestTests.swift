@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralManifestTests {
    @Test func startsInNew() throws {
        let item = Referrals.newReferralManifest("code-525", name: "name-102")
        #expect(item.status == Referrals.ReferralManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newReferralManifest("code-525", name: "name-102")
        try item.moveTo(Referrals.ReferralManifestStatus.failed)
        #expect(item.status == Referrals.ReferralManifestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newReferralManifest("code-525", name: "name-102")
        item.status = Referrals.ReferralManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralManifestStatus.new) }
    }
}
