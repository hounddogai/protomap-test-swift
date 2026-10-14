@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAllocationTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAccessionAllocation("code-486", title: "title-473")
        #expect(item.status == Labs.AccessionAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newAccessionAllocation("code-486", title: "title-473")
        try item.moveTo(Labs.AccessionAllocationStatus.rejected)
        #expect(item.status == Labs.AccessionAllocationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAccessionAllocation("code-486", title: "title-473")
        item.status = Labs.AccessionAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionAllocationStatus.proposed) }
    }
}
