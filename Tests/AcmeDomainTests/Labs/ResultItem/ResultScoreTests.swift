@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultScoreTests {
    @Test func startsInOpen() throws {
        let item = Labs.newResultScore("code-944", name: "name-985")
        #expect(item.status == Labs.ResultScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newResultScore("code-944", name: "name-985")
        try item.moveTo(Labs.ResultScoreStatus.inReview)
        #expect(item.status == Labs.ResultScoreStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newResultScore("code-944", name: "name-985")
        item.status = Labs.ResultScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultScoreStatus.`open`) }
    }
}
