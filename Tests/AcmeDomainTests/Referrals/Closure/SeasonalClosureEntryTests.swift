@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureEntryTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newSeasonalClosureEntry("code-724", title: "title-174")
        #expect(item.status == Referrals.SeasonalClosureEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newSeasonalClosureEntry("code-724", title: "title-174")
        try item.moveTo(Referrals.SeasonalClosureEntryStatus.ready)
        #expect(item.status == Referrals.SeasonalClosureEntryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newSeasonalClosureEntry("code-724", title: "title-174")
        item.status = Referrals.SeasonalClosureEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureEntryStatus.idle) }
    }
}
