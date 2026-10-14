@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelTemplateTests {
    @Test func startsInNew() throws {
        let item = Labs.newGlobalPanelTemplate("code-766", label: "label-841")
        #expect(item.status == Labs.GlobalPanelTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newGlobalPanelTemplate("code-766", label: "label-841")
        try item.moveTo(Labs.GlobalPanelTemplateStatus.running)
        #expect(item.status == Labs.GlobalPanelTemplateStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newGlobalPanelTemplate("code-766", label: "label-841")
        item.status = Labs.GlobalPanelTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalPanelTemplateStatus.new) }
    }
}
