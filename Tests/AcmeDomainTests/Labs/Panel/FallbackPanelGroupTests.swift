@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelGroupTests {
    @Test func startsInProposed() throws {
        let item = Labs.newFallbackPanelGroup("code-296", name: "name-977")
        #expect(item.status == Labs.FallbackPanelGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newFallbackPanelGroup("code-296", name: "name-977")
        try item.moveTo(Labs.FallbackPanelGroupStatus.rejected)
        #expect(item.status == Labs.FallbackPanelGroupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newFallbackPanelGroup("code-296", name: "name-977")
        item.status = Labs.FallbackPanelGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackPanelGroupStatus.proposed) }
    }
}
