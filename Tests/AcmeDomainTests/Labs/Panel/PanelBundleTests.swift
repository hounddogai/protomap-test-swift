@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBundleTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelBundle("code-837", name: "name-18")
        #expect(item.status == Labs.PanelBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newPanelBundle("code-837", name: "name-18")
        try item.moveTo(Labs.PanelBundleStatus.withdrawn)
        #expect(item.status == Labs.PanelBundleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelBundle("code-837", name: "name-18")
        item.status = Labs.PanelBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelBundleStatus.proposed) }
    }
}
