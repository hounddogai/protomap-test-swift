@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeRecordTests {
    @Test func startsInRequested() throws {
        let item = Labs.newBatchedReferenceRangeRecord("code-576", title: "title-512")
        #expect(item.status == Labs.BatchedReferenceRangeRecordStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newBatchedReferenceRangeRecord("code-576", title: "title-512")
        try item.moveTo(Labs.BatchedReferenceRangeRecordStatus.granted)
        #expect(item.status == Labs.BatchedReferenceRangeRecordStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newBatchedReferenceRangeRecord("code-576", title: "title-512")
        item.status = Labs.BatchedReferenceRangeRecordStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedReferenceRangeRecordStatus.requested) }
    }
}
