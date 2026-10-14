@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAllocationTests {
    @Test func startsInProposed() throws {
        let item = Labs.newResultAllocation("code-587", title: "title-434")
        #expect(item.status == Labs.ResultAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newResultAllocation("code-587", title: "title-434")
        try item.moveTo(Labs.ResultAllocationStatus.approved)
        #expect(item.status == Labs.ResultAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newResultAllocation("code-587", title: "title-434")
        item.status = Labs.ResultAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultAllocationStatus.proposed) }
    }
}
