@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReviewTests {
    @Test func startsInOpen() throws {
        let item = Labs.newAccessionReview("code-966", name: "name-453")
        #expect(item.status == Labs.AccessionReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newAccessionReview("code-966", name: "name-453")
        try item.moveTo(Labs.AccessionReviewStatus.resolved)
        #expect(item.status == Labs.AccessionReviewStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newAccessionReview("code-966", name: "name-453")
        item.status = Labs.AccessionReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionReviewStatus.`open`) }
    }
}
