@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkScoreTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newLenientNetworkScore("code-6", label: "label-570")
        #expect(item.status == Referrals.LenientNetworkScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Referrals.newLenientNetworkScore("code-6", label: "label-570")
        try item.moveTo(Referrals.LenientNetworkScoreStatus.cancelled)
        #expect(item.status == Referrals.LenientNetworkScoreStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newLenientNetworkScore("code-6", label: "label-570")
        item.status = Referrals.LenientNetworkScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientNetworkScoreStatus.planned) }
    }
}
