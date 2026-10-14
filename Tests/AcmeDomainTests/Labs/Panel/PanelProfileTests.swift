@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelProfileTests {
    @Test func startsInNew() throws {
        let item = Labs.newPanelProfile("code-739", name: "name-541")
        #expect(item.status == Labs.PanelProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newPanelProfile("code-739", name: "name-541")
        try item.moveTo(Labs.PanelProfileStatus.queued)
        #expect(item.status == Labs.PanelProfileStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPanelProfile("code-739", name: "name-541")
        item.status = Labs.PanelProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelProfileStatus.new) }
    }
}
