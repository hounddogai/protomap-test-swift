@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePreferenceTests {
    @Test func startsInNew() throws {
        let item = Referrals.newClosurePreference("code-255", title: "title-703")
        #expect(item.status == Referrals.ClosurePreferenceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newClosurePreference("code-255", title: "title-703")
        try item.moveTo(Referrals.ClosurePreferenceStatus.queued)
        #expect(item.status == Referrals.ClosurePreferenceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newClosurePreference("code-255", title: "title-703")
        item.status = Referrals.ClosurePreferenceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosurePreferenceStatus.new) }
    }
}
