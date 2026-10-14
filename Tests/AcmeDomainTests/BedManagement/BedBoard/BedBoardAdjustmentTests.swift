@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBedBoardAdjustment("code-740", label: "label-360")
        #expect(item.status == BedManagement.BedBoardAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newBedBoardAdjustment("code-740", label: "label-360")
        try item.moveTo(BedManagement.BedBoardAdjustmentStatus.reopened)
        #expect(item.status == BedManagement.BedBoardAdjustmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBedBoardAdjustment("code-740", label: "label-360")
        item.status = BedManagement.BedBoardAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardAdjustmentStatus.`open`) }
    }
}
