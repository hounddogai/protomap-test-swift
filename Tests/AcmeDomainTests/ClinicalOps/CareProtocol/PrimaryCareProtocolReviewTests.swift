@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryCareProtocolReviewTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newPrimaryCareProtocolReview("code-756", title: "title-817")
        #expect(item.status == ClinicalOps.PrimaryCareProtocolReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newPrimaryCareProtocolReview("code-756", title: "title-817")
        try item.moveTo(ClinicalOps.PrimaryCareProtocolReviewStatus.granted)
        #expect(item.status == ClinicalOps.PrimaryCareProtocolReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newPrimaryCareProtocolReview("code-756", title: "title-817")
        item.status = ClinicalOps.PrimaryCareProtocolReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryCareProtocolReviewStatus.requested) }
    }
}
