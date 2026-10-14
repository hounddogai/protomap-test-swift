@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newReferenceRangeAllocation("code-299", label: "label-737")
        #expect(item.status == Labs.ReferenceRangeAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newReferenceRangeAllocation("code-299", label: "label-737")
        try item.moveTo(Labs.ReferenceRangeAllocationStatus.inProgress)
        #expect(item.status == Labs.ReferenceRangeAllocationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newReferenceRangeAllocation("code-299", label: "label-737")
        item.status = Labs.ReferenceRangeAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeAllocationStatus.planned) }
    }
}
