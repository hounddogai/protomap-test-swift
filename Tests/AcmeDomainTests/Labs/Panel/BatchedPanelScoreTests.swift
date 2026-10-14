@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedPanelScoreTests {
    @Test func startsInCreated() throws {
        let item = Labs.newBatchedPanelScore("code-579", title: "title-376")
        #expect(item.status == Labs.BatchedPanelScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newBatchedPanelScore("code-579", title: "title-376")
        try item.moveTo(Labs.BatchedPanelScoreStatus.validated)
        #expect(item.status == Labs.BatchedPanelScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newBatchedPanelScore("code-579", title: "title-376")
        item.status = Labs.BatchedPanelScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedPanelScoreStatus.created) }
    }
}
