@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newGlobalPanelAdjustment("code-908", title: "title-873")
        #expect(item.status == Labs.GlobalPanelAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newGlobalPanelAdjustment("code-908", title: "title-873")
        try item.moveTo(Labs.GlobalPanelAdjustmentStatus.completed)
        #expect(item.status == Labs.GlobalPanelAdjustmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newGlobalPanelAdjustment("code-908", title: "title-873")
        item.status = Labs.GlobalPanelAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalPanelAdjustmentStatus.planned) }
    }
}
