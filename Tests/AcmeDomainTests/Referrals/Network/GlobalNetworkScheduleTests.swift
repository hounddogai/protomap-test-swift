@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkScheduleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newGlobalNetworkSchedule("code-787", name: "name-817")
        #expect(item.status == Referrals.GlobalNetworkScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newGlobalNetworkSchedule("code-787", name: "name-817")
        try item.moveTo(Referrals.GlobalNetworkScheduleStatus.running)
        #expect(item.status == Referrals.GlobalNetworkScheduleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newGlobalNetworkSchedule("code-787", name: "name-817")
        item.status = Referrals.GlobalNetworkScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalNetworkScheduleStatus.new) }
    }
}
