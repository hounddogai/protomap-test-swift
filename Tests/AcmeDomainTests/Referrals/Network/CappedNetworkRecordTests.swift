@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkRecordTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newCappedNetworkRecord("code-286", name: "name-264")
        #expect(item.status == Referrals.CappedNetworkRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newCappedNetworkRecord("code-286", name: "name-264")
        try item.moveTo(Referrals.CappedNetworkRecordStatus.rejected)
        #expect(item.status == Referrals.CappedNetworkRecordStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newCappedNetworkRecord("code-286", name: "name-264")
        item.status = Referrals.CappedNetworkRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedNetworkRecordStatus.proposed) }
    }
}
