@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeBatchTests {
    @Test func startsInNew() throws {
        let item = Labs.newPendingReferenceRangeBatch("code-912", title: "title-701")
        #expect(item.status == Labs.PendingReferenceRangeBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newPendingReferenceRangeBatch("code-912", title: "title-701")
        try item.moveTo(Labs.PendingReferenceRangeBatchStatus.failed)
        #expect(item.status == Labs.PendingReferenceRangeBatchStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPendingReferenceRangeBatch("code-912", title: "title-701")
        item.status = Labs.PendingReferenceRangeBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingReferenceRangeBatchStatus.new) }
    }
}
