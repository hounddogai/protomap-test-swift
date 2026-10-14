@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictPanelAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Labs.newStrictPanelAssignment("code-231", title: "title-94")
        #expect(item.status == Labs.StrictPanelAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newStrictPanelAssignment("code-231", title: "title-94")
        try item.moveTo(Labs.StrictPanelAssignmentStatus.approved)
        #expect(item.status == Labs.StrictPanelAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newStrictPanelAssignment("code-231", title: "title-94")
        item.status = Labs.StrictPanelAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictPanelAssignmentStatus.proposed) }
    }
}
