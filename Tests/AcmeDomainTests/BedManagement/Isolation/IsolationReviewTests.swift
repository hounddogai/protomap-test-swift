@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationReviewTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationReview("code-91", title: "title-972")
        #expect(item.status == BedManagement.IsolationReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newIsolationReview("code-91", title: "title-972")
        try item.moveTo(BedManagement.IsolationReviewStatus.warming)
        #expect(item.status == BedManagement.IsolationReviewStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationReview("code-91", title: "title-972")
        item.status = BedManagement.IsolationReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationReviewStatus.idle) }
    }
}
