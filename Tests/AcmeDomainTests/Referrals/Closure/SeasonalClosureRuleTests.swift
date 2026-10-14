@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureRuleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSeasonalClosureRule("code-497", label: "label-382")
        #expect(item.status == Referrals.SeasonalClosureRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newSeasonalClosureRule("code-497", label: "label-382")
        try item.moveTo(Referrals.SeasonalClosureRuleStatus.queued)
        #expect(item.status == Referrals.SeasonalClosureRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSeasonalClosureRule("code-497", label: "label-382")
        item.status = Referrals.SeasonalClosureRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureRuleStatus.new) }
    }
}
