@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkWindowTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newLenientNetworkWindow("code-315", title: "title-43")
        #expect(item.status == Referrals.LenientNetworkWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newLenientNetworkWindow("code-315", title: "title-43")
        try item.moveTo(Referrals.LenientNetworkWindowStatus.inProgress)
        #expect(item.status == Referrals.LenientNetworkWindowStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newLenientNetworkWindow("code-315", title: "title-43")
        item.status = Referrals.LenientNetworkWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientNetworkWindowStatus.planned) }
    }
}
