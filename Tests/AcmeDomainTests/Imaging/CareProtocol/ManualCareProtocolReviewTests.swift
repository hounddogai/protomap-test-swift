@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolReviewTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newManualCareProtocolReview("code-383", title: "title-942")
        #expect(item.status == Imaging.ManualCareProtocolReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newManualCareProtocolReview("code-383", title: "title-942")
        try item.moveTo(Imaging.ManualCareProtocolReviewStatus.revoked)
        #expect(item.status == Imaging.ManualCareProtocolReviewStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newManualCareProtocolReview("code-383", title: "title-942")
        item.status = Imaging.ManualCareProtocolReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualCareProtocolReviewStatus.requested) }
    }
}
