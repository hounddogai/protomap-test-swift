@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRequestTests {
    @Test func startsInProposed() throws {
        let item = Labs.newReferenceRangeRequest("code-983", label: "label-807")
        #expect(item.status == Labs.ReferenceRangeRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newReferenceRangeRequest("code-983", label: "label-807")
        try item.moveTo(Labs.ReferenceRangeRequestStatus.approved)
        #expect(item.status == Labs.ReferenceRangeRequestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newReferenceRangeRequest("code-983", label: "label-807")
        item.status = Labs.ReferenceRangeRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeRequestStatus.proposed) }
    }
}
