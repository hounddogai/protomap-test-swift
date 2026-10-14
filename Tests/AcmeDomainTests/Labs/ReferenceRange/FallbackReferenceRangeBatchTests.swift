@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeBatchTests {
    @Test func startsInRequested() throws {
        let item = Labs.newFallbackReferenceRangeBatch("code-655", title: "title-240")
        #expect(item.status == Labs.FallbackReferenceRangeBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newFallbackReferenceRangeBatch("code-655", title: "title-240")
        try item.moveTo(Labs.FallbackReferenceRangeBatchStatus.granted)
        #expect(item.status == Labs.FallbackReferenceRangeBatchStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newFallbackReferenceRangeBatch("code-655", title: "title-240")
        item.status = Labs.FallbackReferenceRangeBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackReferenceRangeBatchStatus.requested) }
    }
}
