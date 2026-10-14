@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeMappingTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newBatchedReferenceRangeMapping("code-297", name: "name-848")
        #expect(item.status == Labs.BatchedReferenceRangeMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Labs.newBatchedReferenceRangeMapping("code-297", name: "name-848")
        try item.moveTo(Labs.BatchedReferenceRangeMappingStatus.cancelled)
        #expect(item.status == Labs.BatchedReferenceRangeMappingStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newBatchedReferenceRangeMapping("code-297", name: "name-848")
        item.status = Labs.BatchedReferenceRangeMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedReferenceRangeMappingStatus.planned) }
    }
}
