@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultScoreTests {
    @Test func startsInOpen() throws {
        let item = Labs.newWeightedResultScore("code-892", name: "name-189")
        #expect(item.status == Labs.WeightedResultScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newWeightedResultScore("code-892", name: "name-189")
        try item.moveTo(Labs.WeightedResultScoreStatus.inReview)
        #expect(item.status == Labs.WeightedResultScoreStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newWeightedResultScore("code-892", name: "name-189")
        item.status = Labs.WeightedResultScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedResultScoreStatus.`open`) }
    }
}
