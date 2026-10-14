@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalNetworkCycleTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newSeasonalNetworkCycle("code-933", name: "name-643")
        #expect(item.status == Referrals.SeasonalNetworkCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newSeasonalNetworkCycle("code-933", name: "name-643")
        try item.moveTo(Referrals.SeasonalNetworkCycleStatus.inProgress)
        #expect(item.status == Referrals.SeasonalNetworkCycleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newSeasonalNetworkCycle("code-933", name: "name-643")
        item.status = Referrals.SeasonalNetworkCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalNetworkCycleStatus.planned) }
    }
}
