@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureWindowTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSeasonalClosureWindow("code-495", label: "label-14")
        #expect(item.status == Referrals.SeasonalClosureWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newSeasonalClosureWindow("code-495", label: "label-14")
        try item.moveTo(Referrals.SeasonalClosureWindowStatus.queued)
        #expect(item.status == Referrals.SeasonalClosureWindowStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSeasonalClosureWindow("code-495", label: "label-14")
        item.status = Referrals.SeasonalClosureWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureWindowStatus.new) }
    }
}
