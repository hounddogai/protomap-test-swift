@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newClosureAdjustment("code-528", title: "title-234")
        #expect(item.status == Referrals.ClosureAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newClosureAdjustment("code-528", title: "title-234")
        try item.moveTo(Referrals.ClosureAdjustmentStatus.scheduled)
        #expect(item.status == Referrals.ClosureAdjustmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newClosureAdjustment("code-528", title: "title-234")
        item.status = Referrals.ClosureAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureAdjustmentStatus.planned) }
    }
}
