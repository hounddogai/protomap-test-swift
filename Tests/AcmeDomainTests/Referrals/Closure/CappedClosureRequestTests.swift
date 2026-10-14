@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureRequestTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newCappedClosureRequest("code-557", title: "title-916")
        #expect(item.status == Referrals.CappedClosureRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newCappedClosureRequest("code-557", title: "title-916")
        try item.moveTo(Referrals.CappedClosureRequestStatus.scheduled)
        #expect(item.status == Referrals.CappedClosureRequestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newCappedClosureRequest("code-557", title: "title-916")
        item.status = Referrals.CappedClosureRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedClosureRequestStatus.planned) }
    }
}
