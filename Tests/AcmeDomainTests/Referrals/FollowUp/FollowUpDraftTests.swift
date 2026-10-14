@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpDraftTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newFollowUpDraft("code-455", label: "label-590")
        #expect(item.status == Referrals.FollowUpDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newFollowUpDraft("code-455", label: "label-590")
        try item.moveTo(Referrals.FollowUpDraftStatus.warming)
        #expect(item.status == Referrals.FollowUpDraftStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newFollowUpDraft("code-455", label: "label-590")
        item.status = Referrals.FollowUpDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpDraftStatus.idle) }
    }
}
