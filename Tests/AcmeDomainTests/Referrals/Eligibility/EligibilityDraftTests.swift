@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityDraftTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newEligibilityDraft("code-524", title: "title-277")
        #expect(item.status == Referrals.EligibilityDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newEligibilityDraft("code-524", title: "title-277")
        try item.moveTo(Referrals.EligibilityDraftStatus.warming)
        #expect(item.status == Referrals.EligibilityDraftStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newEligibilityDraft("code-524", title: "title-277")
        item.status = Referrals.EligibilityDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityDraftStatus.idle) }
    }
}
