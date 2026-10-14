@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenReviewTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenReview("code-64", label: "label-23")
        #expect(item.status == Labs.SpecimenReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Labs.newSpecimenReview("code-64", label: "label-23")
        try item.moveTo(Labs.SpecimenReviewStatus.stopped)
        #expect(item.status == Labs.SpecimenReviewStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenReview("code-64", label: "label-23")
        item.status = Labs.SpecimenReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenReviewStatus.idle) }
    }
}
