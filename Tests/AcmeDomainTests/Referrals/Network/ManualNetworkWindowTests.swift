@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkWindowTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newManualNetworkWindow("code-806", label: "label-161")
        #expect(item.status == Referrals.ManualNetworkWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newManualNetworkWindow("code-806", label: "label-161")
        try item.moveTo(Referrals.ManualNetworkWindowStatus.rejected)
        #expect(item.status == Referrals.ManualNetworkWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newManualNetworkWindow("code-806", label: "label-161")
        item.status = Referrals.ManualNetworkWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkWindowStatus.proposed) }
    }
}
