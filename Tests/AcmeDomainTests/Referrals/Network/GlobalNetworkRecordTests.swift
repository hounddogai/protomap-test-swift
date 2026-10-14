@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkRecordTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newGlobalNetworkRecord("code-929", label: "label-961")
        #expect(item.status == Referrals.GlobalNetworkRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newGlobalNetworkRecord("code-929", label: "label-961")
        try item.moveTo(Referrals.GlobalNetworkRecordStatus.rejected)
        #expect(item.status == Referrals.GlobalNetworkRecordStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newGlobalNetworkRecord("code-929", label: "label-961")
        item.status = Referrals.GlobalNetworkRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalNetworkRecordStatus.proposed) }
    }
}
