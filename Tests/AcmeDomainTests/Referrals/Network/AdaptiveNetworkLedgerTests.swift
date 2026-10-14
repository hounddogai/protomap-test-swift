@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkLedgerTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newAdaptiveNetworkLedger("code-787", name: "name-611")
        #expect(item.status == Referrals.AdaptiveNetworkLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newAdaptiveNetworkLedger("code-787", name: "name-611")
        try item.moveTo(Referrals.AdaptiveNetworkLedgerStatus.inReview)
        #expect(item.status == Referrals.AdaptiveNetworkLedgerStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newAdaptiveNetworkLedger("code-787", name: "name-611")
        item.status = Referrals.AdaptiveNetworkLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveNetworkLedgerStatus.`open`) }
    }
}
