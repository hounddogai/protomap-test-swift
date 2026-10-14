@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierTierTests {
    @Test func startsInOpen() throws {
        let item = Labs.newBatchedCourierTier("code-973", label: "label-41")
        #expect(item.status == Labs.BatchedCourierTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newBatchedCourierTier("code-973", label: "label-41")
        try item.moveTo(Labs.BatchedCourierTierStatus.reopened)
        #expect(item.status == Labs.BatchedCourierTierStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newBatchedCourierTier("code-973", label: "label-41")
        item.status = Labs.BatchedCourierTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedCourierTierStatus.`open`) }
    }
}
