@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelEstimateTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPanelEstimate("code-603", title: "title-94")
        #expect(item.status == Labs.PanelEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newPanelEstimate("code-603", title: "title-94")
        try item.moveTo(Labs.PanelEstimateStatus.approved)
        #expect(item.status == Labs.PanelEstimateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPanelEstimate("code-603", title: "title-94")
        item.status = Labs.PanelEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelEstimateStatus.proposed) }
    }
}
