@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelManifestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelManifest("code-151", label: "label-819")
        #expect(item.status == Labs.PanelManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newPanelManifest("code-151", label: "label-819")
        try item.moveTo(Labs.PanelManifestStatus.approved)
        #expect(item.status == Labs.PanelManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelManifest("code-151", label: "label-819")
        item.status = Labs.PanelManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelManifestStatus.proposed) }
    }
}
