@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newFallbackBedBoardAdjustment("code-490", label: "label-475")
        #expect(item.status == BedManagement.FallbackBedBoardAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newFallbackBedBoardAdjustment("code-490", label: "label-475")
        try item.moveTo(BedManagement.FallbackBedBoardAdjustmentStatus.inProgress)
        #expect(item.status == BedManagement.FallbackBedBoardAdjustmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newFallbackBedBoardAdjustment("code-490", label: "label-475")
        item.status = BedManagement.FallbackBedBoardAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackBedBoardAdjustmentStatus.planned) }
    }
}
