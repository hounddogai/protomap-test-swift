@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionReviewTests {
    @Test func startsInProposed() throws {
        let item = Labs.newFallbackAccessionReview("code-590", label: "label-212")
        #expect(item.status == Labs.FallbackAccessionReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newFallbackAccessionReview("code-590", label: "label-212")
        try item.moveTo(Labs.FallbackAccessionReviewStatus.approved)
        #expect(item.status == Labs.FallbackAccessionReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newFallbackAccessionReview("code-590", label: "label-212")
        item.status = Labs.FallbackAccessionReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackAccessionReviewStatus.proposed) }
    }
}
