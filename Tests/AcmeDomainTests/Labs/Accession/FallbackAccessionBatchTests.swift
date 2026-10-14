@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionBatchTests {
    @Test func startsInNew() throws {
        let item = Labs.newFallbackAccessionBatch("code-996", title: "title-191")
        #expect(item.status == Labs.FallbackAccessionBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newFallbackAccessionBatch("code-996", title: "title-191")
        try item.moveTo(Labs.FallbackAccessionBatchStatus.failed)
        #expect(item.status == Labs.FallbackAccessionBatchStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newFallbackAccessionBatch("code-996", title: "title-191")
        item.status = Labs.FallbackAccessionBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackAccessionBatchStatus.new) }
    }
}
