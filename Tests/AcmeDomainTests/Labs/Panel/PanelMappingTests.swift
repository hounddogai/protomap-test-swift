@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelMappingTests {
    @Test func startsInDraft() throws {
        let item = Labs.newPanelMapping("code-653", name: "name-310")
        #expect(item.status == Labs.PanelMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newPanelMapping("code-653", name: "name-310")
        try item.moveTo(Labs.PanelMappingStatus.suspended)
        #expect(item.status == Labs.PanelMappingStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newPanelMapping("code-653", name: "name-310")
        item.status = Labs.PanelMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelMappingStatus.draft) }
    }
}
