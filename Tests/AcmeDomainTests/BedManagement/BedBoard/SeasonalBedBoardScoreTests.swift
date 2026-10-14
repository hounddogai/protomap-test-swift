@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalBedBoardScoreTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newSeasonalBedBoardScore("code-322", title: "title-756")
        #expect(item.status == BedManagement.SeasonalBedBoardScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newSeasonalBedBoardScore("code-322", title: "title-756")
        try item.moveTo(BedManagement.SeasonalBedBoardScoreStatus.inProgress)
        #expect(item.status == BedManagement.SeasonalBedBoardScoreStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newSeasonalBedBoardScore("code-322", title: "title-756")
        item.status = BedManagement.SeasonalBedBoardScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.SeasonalBedBoardScoreStatus.planned) }
    }
}
