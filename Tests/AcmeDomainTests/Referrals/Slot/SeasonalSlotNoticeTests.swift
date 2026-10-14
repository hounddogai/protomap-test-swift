@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalSlotNoticeTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSeasonalSlotNotice("code-188", label: "label-768")
        #expect(item.status == Referrals.SeasonalSlotNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newSeasonalSlotNotice("code-188", label: "label-768")
        try item.moveTo(Referrals.SeasonalSlotNoticeStatus.archived)
        #expect(item.status == Referrals.SeasonalSlotNoticeStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSeasonalSlotNotice("code-188", label: "label-768")
        item.status = Referrals.SeasonalSlotNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalSlotNoticeStatus.`open`) }
    }
}
