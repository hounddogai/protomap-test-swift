@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionGroupTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPrimaryAccessionGroup("code-538", label: "label-433")
        #expect(item.status == Labs.PrimaryAccessionGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newPrimaryAccessionGroup("code-538", label: "label-433")
        try item.moveTo(Labs.PrimaryAccessionGroupStatus.approved)
        #expect(item.status == Labs.PrimaryAccessionGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPrimaryAccessionGroup("code-538", label: "label-433")
        item.status = Labs.PrimaryAccessionGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryAccessionGroupStatus.proposed) }
    }
}
