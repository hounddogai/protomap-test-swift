@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTargetTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkTarget("code-319", name: "name-881")
        #expect(item.status == Referrals.NetworkTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newNetworkTarget("code-319", name: "name-881")
        try item.moveTo(Referrals.NetworkTargetStatus.inProgress)
        #expect(item.status == Referrals.NetworkTargetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkTarget("code-319", name: "name-881")
        item.status = Referrals.NetworkTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkTargetStatus.planned) }
    }
}
