@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralExceptionTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newTieredReferralException("code-346", title: "title-112")
        #expect(item.status == Referrals.TieredReferralExceptionStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newTieredReferralException("code-346", title: "title-112")
        try item.moveTo(Referrals.TieredReferralExceptionStatus.completed)
        #expect(item.status == Referrals.TieredReferralExceptionStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newTieredReferralException("code-346", title: "title-112")
        item.status = Referrals.TieredReferralExceptionStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredReferralExceptionStatus.planned) }
    }
}
