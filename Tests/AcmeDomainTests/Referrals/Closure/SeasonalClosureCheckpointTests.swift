@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureCheckpointTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSeasonalClosureCheckpoint("code-834", title: "title-147")
        #expect(item.status == Referrals.SeasonalClosureCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Referrals.newSeasonalClosureCheckpoint("code-834", title: "title-147")
        try item.moveTo(Referrals.SeasonalClosureCheckpointStatus.closed)
        #expect(item.status == Referrals.SeasonalClosureCheckpointStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSeasonalClosureCheckpoint("code-834", title: "title-147")
        item.status = Referrals.SeasonalClosureCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureCheckpointStatus.draft) }
    }
}
