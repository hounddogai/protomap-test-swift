@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapEntryTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newSeasonalCareGapEntry("code-689", title: "title-232")
        #expect(item.status == CareManagement.SeasonalCareGapEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newSeasonalCareGapEntry("code-689", title: "title-232")
        try item.moveTo(CareManagement.SeasonalCareGapEntryStatus.inReview)
        #expect(item.status == CareManagement.SeasonalCareGapEntryStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newSeasonalCareGapEntry("code-689", title: "title-232")
        item.status = CareManagement.SeasonalCareGapEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalCareGapEntryStatus.`open`) }
    }
}
