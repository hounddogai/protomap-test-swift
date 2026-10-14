@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenBatchTests {
    @Test func startsInProposed() throws {
        let item = Labs.newSpecimenBatch("code-175", label: "label-34")
        #expect(item.status == Labs.SpecimenBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newSpecimenBatch("code-175", label: "label-34")
        try item.moveTo(Labs.SpecimenBatchStatus.approved)
        #expect(item.status == Labs.SpecimenBatchStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newSpecimenBatch("code-175", label: "label-34")
        item.status = Labs.SpecimenBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenBatchStatus.proposed) }
    }
}
