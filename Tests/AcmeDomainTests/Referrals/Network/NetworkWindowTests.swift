@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkWindowTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkWindow("code-304", title: "title-917")
        #expect(item.status == Referrals.NetworkWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newNetworkWindow("code-304", title: "title-917")
        try item.moveTo(Referrals.NetworkWindowStatus.scheduled)
        #expect(item.status == Referrals.NetworkWindowStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkWindow("code-304", title: "title-917")
        item.status = Referrals.NetworkWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkWindowStatus.planned) }
    }
}
