@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRollupTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newNetworkRollup("code-914", name: "name-924")
        #expect(item.status == Referrals.NetworkRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newNetworkRollup("code-914", name: "name-924")
        try item.moveTo(Referrals.NetworkRollupStatus.resolved)
        #expect(item.status == Referrals.NetworkRollupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newNetworkRollup("code-914", name: "name-924")
        item.status = Referrals.NetworkRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkRollupStatus.`open`) }
    }
}
