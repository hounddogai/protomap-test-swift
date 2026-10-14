@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPanelOverride("code-681", title: "title-144")
        #expect(item.status == Labs.PanelOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newPanelOverride("code-681", title: "title-144")
        try item.moveTo(Labs.PanelOverrideStatus.inProgress)
        #expect(item.status == Labs.PanelOverrideStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPanelOverride("code-681", title: "title-144")
        item.status = Labs.PanelOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelOverrideStatus.planned) }
    }
}
