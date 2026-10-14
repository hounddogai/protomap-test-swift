@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelTemplateTests {
    @Test func startsInIdle() throws {
        let item = Labs.newPendingPanelTemplate("code-36", name: "name-49")
        #expect(item.status == Labs.PendingPanelTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newPendingPanelTemplate("code-36", name: "name-49")
        try item.moveTo(Labs.PendingPanelTemplateStatus.warming)
        #expect(item.status == Labs.PendingPanelTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newPendingPanelTemplate("code-36", name: "name-49")
        item.status = Labs.PendingPanelTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingPanelTemplateStatus.idle) }
    }
}
