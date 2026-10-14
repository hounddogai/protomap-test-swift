@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierReviewTests {
    @Test func startsInOpen() throws {
        let item = Labs.newCourierReview("code-625", name: "name-631")
        #expect(item.status == Labs.CourierReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newCourierReview("code-625", name: "name-631")
        try item.moveTo(Labs.CourierReviewStatus.reopened)
        #expect(item.status == Labs.CourierReviewStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newCourierReview("code-625", name: "name-631")
        item.status = Labs.CourierReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierReviewStatus.`open`) }
    }
}
