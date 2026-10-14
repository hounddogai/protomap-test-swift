@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierReviewTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCappedCourierReview("code-504", title: "title-870")
        #expect(item.status == Labs.CappedCourierReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newCappedCourierReview("code-504", title: "title-870")
        try item.moveTo(Labs.CappedCourierReviewStatus.draining)
        #expect(item.status == Labs.CappedCourierReviewStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCappedCourierReview("code-504", title: "title-870")
        item.status = Labs.CappedCourierReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedCourierReviewStatus.idle) }
    }
}
