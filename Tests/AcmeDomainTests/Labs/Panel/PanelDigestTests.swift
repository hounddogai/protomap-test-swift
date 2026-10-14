@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelDigestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelDigest("code-625", name: "name-179")
        #expect(item.status == Labs.PanelDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newPanelDigest("code-625", name: "name-179")
        try item.moveTo(Labs.PanelDigestStatus.approved)
        #expect(item.status == Labs.PanelDigestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelDigest("code-625", name: "name-179")
        item.status = Labs.PanelDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelDigestStatus.proposed) }
    }
}
