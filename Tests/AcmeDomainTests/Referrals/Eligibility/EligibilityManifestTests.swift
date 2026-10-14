@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityManifestTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newEligibilityManifest("code-196", title: "title-516")
        #expect(item.status == Referrals.EligibilityManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newEligibilityManifest("code-196", title: "title-516")
        try item.moveTo(Referrals.EligibilityManifestStatus.scheduled)
        #expect(item.status == Referrals.EligibilityManifestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newEligibilityManifest("code-196", title: "title-516")
        item.status = Referrals.EligibilityManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityManifestStatus.planned) }
    }
}
