@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Labs.newScheduledPanelAdjustment("code-826", label: "label-526")
        #expect(item.status == Labs.ScheduledPanelAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newScheduledPanelAdjustment("code-826", label: "label-526")
        try item.moveTo(Labs.ScheduledPanelAdjustmentStatus.resolved)
        #expect(item.status == Labs.ScheduledPanelAdjustmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newScheduledPanelAdjustment("code-826", label: "label-526")
        item.status = Labs.ScheduledPanelAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledPanelAdjustmentStatus.`open`) }
    }
}
