@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpScheduleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newFollowUpSchedule("code-985", label: "label-862")
        #expect(item.status == Referrals.FollowUpScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newFollowUpSchedule("code-985", label: "label-862")
        try item.moveTo(Referrals.FollowUpScheduleStatus.running)
        #expect(item.status == Referrals.FollowUpScheduleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newFollowUpSchedule("code-985", label: "label-862")
        item.status = Referrals.FollowUpScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpScheduleStatus.new) }
    }
}
