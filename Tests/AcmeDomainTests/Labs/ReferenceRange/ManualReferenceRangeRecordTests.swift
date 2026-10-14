@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeRecordTests {
    @Test func startsInProposed() throws {
        let item = Labs.newManualReferenceRangeRecord("code-389", label: "label-321")
        #expect(item.status == Labs.ManualReferenceRangeRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newManualReferenceRangeRecord("code-389", label: "label-321")
        try item.moveTo(Labs.ManualReferenceRangeRecordStatus.approved)
        #expect(item.status == Labs.ManualReferenceRangeRecordStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newManualReferenceRangeRecord("code-389", label: "label-321")
        item.status = Labs.ManualReferenceRangeRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualReferenceRangeRecordStatus.proposed) }
    }
}
