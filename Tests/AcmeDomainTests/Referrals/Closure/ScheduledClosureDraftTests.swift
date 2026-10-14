@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledClosureDraftTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newScheduledClosureDraft("code-167", name: "name-532")
        #expect(item.status == Referrals.ScheduledClosureDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newScheduledClosureDraft("code-167", name: "name-532")
        try item.moveTo(Referrals.ScheduledClosureDraftStatus.granted)
        #expect(item.status == Referrals.ScheduledClosureDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newScheduledClosureDraft("code-167", name: "name-532")
        item.status = Referrals.ScheduledClosureDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledClosureDraftStatus.requested) }
    }
}
