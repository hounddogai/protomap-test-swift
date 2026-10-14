@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkSchedule("code-350", title: "title-499")
        #expect(item.status == Referrals.NetworkScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newNetworkSchedule("code-350", title: "title-499")
        try item.moveTo(Referrals.NetworkScheduleStatus.completed)
        #expect(item.status == Referrals.NetworkScheduleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkSchedule("code-350", title: "title-499")
        item.status = Referrals.NetworkScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkScheduleStatus.planned) }
    }
}
