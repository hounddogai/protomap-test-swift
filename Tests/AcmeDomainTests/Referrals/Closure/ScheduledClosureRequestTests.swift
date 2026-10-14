@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledClosureRequestTests {
    @Test func startsInNew() throws {
        let item = Referrals.newScheduledClosureRequest("code-914", title: "title-762")
        #expect(item.status == Referrals.ScheduledClosureRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newScheduledClosureRequest("code-914", title: "title-762")
        try item.moveTo(Referrals.ScheduledClosureRequestStatus.running)
        #expect(item.status == Referrals.ScheduledClosureRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newScheduledClosureRequest("code-914", title: "title-762")
        item.status = Referrals.ScheduledClosureRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledClosureRequestStatus.new) }
    }
}
