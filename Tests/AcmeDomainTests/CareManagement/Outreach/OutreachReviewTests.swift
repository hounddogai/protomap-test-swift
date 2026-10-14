@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachReviewTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newOutreachReview("code-677", title: "title-500")
        #expect(item.status == CareManagement.OutreachReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newOutreachReview("code-677", title: "title-500")
        try item.moveTo(CareManagement.OutreachReviewStatus.ready)
        #expect(item.status == CareManagement.OutreachReviewStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newOutreachReview("code-677", title: "title-500")
        item.status = CareManagement.OutreachReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachReviewStatus.idle) }
    }
}
