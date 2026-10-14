@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelWindowTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPanelWindow("code-648", name: "name-974")
        #expect(item.status == Labs.PanelWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newPanelWindow("code-648", name: "name-974")
        try item.moveTo(Labs.PanelWindowStatus.reopened)
        #expect(item.status == Labs.PanelWindowStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPanelWindow("code-648", name: "name-974")
        item.status = Labs.PanelWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelWindowStatus.`open`) }
    }
}
