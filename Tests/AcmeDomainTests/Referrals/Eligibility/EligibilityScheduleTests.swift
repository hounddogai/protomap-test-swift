@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityScheduleTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newEligibilitySchedule("code-114", label: "label-974")
        #expect(item.status == Referrals.EligibilityScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newEligibilitySchedule("code-114", label: "label-974")
        try item.moveTo(Referrals.EligibilityScheduleStatus.ready)
        #expect(item.status == Referrals.EligibilityScheduleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newEligibilitySchedule("code-114", label: "label-974")
        item.status = Referrals.EligibilityScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityScheduleStatus.idle) }
    }
}
