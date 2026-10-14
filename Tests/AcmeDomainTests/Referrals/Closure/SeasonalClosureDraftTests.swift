@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureDraftTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSeasonalClosureDraft("code-673", title: "title-87")
        #expect(item.status == Referrals.SeasonalClosureDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newSeasonalClosureDraft("code-673", title: "title-87")
        try item.moveTo(Referrals.SeasonalClosureDraftStatus.archived)
        #expect(item.status == Referrals.SeasonalClosureDraftStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSeasonalClosureDraft("code-673", title: "title-87")
        item.status = Referrals.SeasonalClosureDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureDraftStatus.`open`) }
    }
}
