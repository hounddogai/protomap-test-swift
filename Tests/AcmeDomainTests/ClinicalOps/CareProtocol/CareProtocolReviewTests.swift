@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolReviewTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newCareProtocolReview("code-525", label: "label-599")
        #expect(item.status == ClinicalOps.CareProtocolReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newCareProtocolReview("code-525", label: "label-599")
        try item.moveTo(ClinicalOps.CareProtocolReviewStatus.pending)
        #expect(item.status == ClinicalOps.CareProtocolReviewStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newCareProtocolReview("code-525", label: "label-599")
        item.status = ClinicalOps.CareProtocolReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolReviewStatus.draft) }
    }
}
