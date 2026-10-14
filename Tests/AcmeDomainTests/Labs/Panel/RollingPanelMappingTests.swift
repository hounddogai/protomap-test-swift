@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelMappingTests {
    @Test func startsInNew() throws {
        let item = Labs.newRollingPanelMapping("code-323", label: "label-282")
        #expect(item.status == Labs.RollingPanelMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newRollingPanelMapping("code-323", label: "label-282")
        try item.moveTo(Labs.RollingPanelMappingStatus.queued)
        #expect(item.status == Labs.RollingPanelMappingStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newRollingPanelMapping("code-323", label: "label-282")
        item.status = Labs.RollingPanelMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingPanelMappingStatus.new) }
    }
}
