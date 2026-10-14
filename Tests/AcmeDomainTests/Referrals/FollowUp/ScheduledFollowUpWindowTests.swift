@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpWindowTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newScheduledFollowUpWindow("code-482", name: "name-287")
        #expect(item.status == Referrals.ScheduledFollowUpWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newScheduledFollowUpWindow("code-482", name: "name-287")
        try item.moveTo(Referrals.ScheduledFollowUpWindowStatus.scheduled)
        #expect(item.status == Referrals.ScheduledFollowUpWindowStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newScheduledFollowUpWindow("code-482", name: "name-287")
        item.status = Referrals.ScheduledFollowUpWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpWindowStatus.planned) }
    }
}
