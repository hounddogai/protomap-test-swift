@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolReviewTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolReview("code-976", label: "label-301")
        #expect(item.status == Imaging.CareProtocolReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newCareProtocolReview("code-976", label: "label-301")
        try item.moveTo(Imaging.CareProtocolReviewStatus.done)
        #expect(item.status == Imaging.CareProtocolReviewStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolReview("code-976", label: "label-301")
        item.status = Imaging.CareProtocolReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolReviewStatus.new) }
    }
}
