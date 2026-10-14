@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBatchTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newAccessionBatch("code-172", title: "title-862")
        #expect(item.status == Labs.AccessionBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newAccessionBatch("code-172", title: "title-862")
        try item.moveTo(Labs.AccessionBatchStatus.inProgress)
        #expect(item.status == Labs.AccessionBatchStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newAccessionBatch("code-172", title: "title-862")
        item.status = Labs.AccessionBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionBatchStatus.planned) }
    }
}
