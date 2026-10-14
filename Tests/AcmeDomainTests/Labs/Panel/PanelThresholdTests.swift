@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelThresholdTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPanelThreshold("code-510", label: "label-496")
        #expect(item.status == Labs.PanelThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newPanelThreshold("code-510", label: "label-496")
        try item.moveTo(Labs.PanelThresholdStatus.granted)
        #expect(item.status == Labs.PanelThresholdStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPanelThreshold("code-510", label: "label-496")
        item.status = Labs.PanelThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelThresholdStatus.requested) }
    }
}
