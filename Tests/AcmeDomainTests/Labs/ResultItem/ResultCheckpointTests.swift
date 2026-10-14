@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultCheckpointTests {
    @Test func startsInOpen() throws {
        let item = Labs.newResultCheckpoint("code-146", name: "name-395")
        #expect(item.status == Labs.ResultCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newResultCheckpoint("code-146", name: "name-395")
        try item.moveTo(Labs.ResultCheckpointStatus.inReview)
        #expect(item.status == Labs.ResultCheckpointStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newResultCheckpoint("code-146", name: "name-395")
        item.status = Labs.ResultCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultCheckpointStatus.`open`) }
    }
}
