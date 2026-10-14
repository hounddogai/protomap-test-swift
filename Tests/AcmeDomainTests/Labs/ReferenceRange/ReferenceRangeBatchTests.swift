@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBatchTests {
    @Test func startsInNew() throws {
        let item = Labs.newReferenceRangeBatch("code-825", label: "label-777")
        #expect(item.status == Labs.ReferenceRangeBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newReferenceRangeBatch("code-825", label: "label-777")
        try item.moveTo(Labs.ReferenceRangeBatchStatus.running)
        #expect(item.status == Labs.ReferenceRangeBatchStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newReferenceRangeBatch("code-825", label: "label-777")
        item.status = Labs.ReferenceRangeBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeBatchStatus.new) }
    }
}
