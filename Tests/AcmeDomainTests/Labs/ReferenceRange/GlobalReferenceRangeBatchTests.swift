@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeBatchTests {
    @Test func startsInNew() throws {
        let item = Labs.newGlobalReferenceRangeBatch("code-165", title: "title-306")
        #expect(item.status == Labs.GlobalReferenceRangeBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newGlobalReferenceRangeBatch("code-165", title: "title-306")
        try item.moveTo(Labs.GlobalReferenceRangeBatchStatus.done)
        #expect(item.status == Labs.GlobalReferenceRangeBatchStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newGlobalReferenceRangeBatch("code-165", title: "title-306")
        item.status = Labs.GlobalReferenceRangeBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalReferenceRangeBatchStatus.new) }
    }
}
