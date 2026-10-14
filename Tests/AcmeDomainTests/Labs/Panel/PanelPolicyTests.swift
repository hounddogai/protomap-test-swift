@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPolicyTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelPolicy("code-719", title: "title-559")
        #expect(item.status == Labs.PanelPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Labs.newPanelPolicy("code-719", title: "title-559")
        try item.moveTo(Labs.PanelPolicyStatus.withdrawn)
        #expect(item.status == Labs.PanelPolicyStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelPolicy("code-719", title: "title-559")
        item.status = Labs.PanelPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelPolicyStatus.proposed) }
    }
}
