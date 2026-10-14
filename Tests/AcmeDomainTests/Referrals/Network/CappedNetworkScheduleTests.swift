@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkScheduleTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newCappedNetworkSchedule("code-2", label: "label-966")
        #expect(item.status == Referrals.CappedNetworkScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newCappedNetworkSchedule("code-2", label: "label-966")
        try item.moveTo(Referrals.CappedNetworkScheduleStatus.pending)
        #expect(item.status == Referrals.CappedNetworkScheduleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newCappedNetworkSchedule("code-2", label: "label-966")
        item.status = Referrals.CappedNetworkScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedNetworkScheduleStatus.draft) }
    }
}
