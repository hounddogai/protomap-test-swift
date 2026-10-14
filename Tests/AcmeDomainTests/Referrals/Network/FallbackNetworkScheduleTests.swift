@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkScheduleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newFallbackNetworkSchedule("code-824", name: "name-436")
        #expect(item.status == Referrals.FallbackNetworkScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Referrals.newFallbackNetworkSchedule("code-824", name: "name-436")
        try item.moveTo(Referrals.FallbackNetworkScheduleStatus.withdrawn)
        #expect(item.status == Referrals.FallbackNetworkScheduleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newFallbackNetworkSchedule("code-824", name: "name-436")
        item.status = Referrals.FallbackNetworkScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackNetworkScheduleStatus.proposed) }
    }
}
