@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyNetworkScoreTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLegacyNetworkScore("code-945", title: "title-348")
        #expect(item.status == Referrals.LegacyNetworkScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newLegacyNetworkScore("code-945", title: "title-348")
        try item.moveTo(Referrals.LegacyNetworkScoreStatus.archived)
        #expect(item.status == Referrals.LegacyNetworkScoreStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLegacyNetworkScore("code-945", title: "title-348")
        item.status = Referrals.LegacyNetworkScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LegacyNetworkScoreStatus.`open`) }
    }
}
