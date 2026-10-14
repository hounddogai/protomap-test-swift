@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelBundleTests {
    @Test func startsInProposed() throws {
        let item = Labs.newFallbackPanelBundle("code-371", name: "name-46")
        #expect(item.status == Labs.FallbackPanelBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newFallbackPanelBundle("code-371", name: "name-46")
        try item.moveTo(Labs.FallbackPanelBundleStatus.withdrawn)
        #expect(item.status == Labs.FallbackPanelBundleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newFallbackPanelBundle("code-371", name: "name-46")
        item.status = Labs.FallbackPanelBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackPanelBundleStatus.proposed) }
    }
}
