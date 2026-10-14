@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkScheduleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newManualNetworkSchedule("code-76", name: "name-995")
        #expect(item.status == Referrals.ManualNetworkScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newManualNetworkSchedule("code-76", name: "name-995")
        try item.moveTo(Referrals.ManualNetworkScheduleStatus.rejected)
        #expect(item.status == Referrals.ManualNetworkScheduleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newManualNetworkSchedule("code-76", name: "name-995")
        item.status = Referrals.ManualNetworkScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkScheduleStatus.proposed) }
    }
}
