@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationReviewTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCappedIsolationReview("code-764", name: "name-966")
        #expect(item.status == BedManagement.CappedIsolationReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = BedManagement.newCappedIsolationReview("code-764", name: "name-966")
        try item.moveTo(BedManagement.CappedIsolationReviewStatus.archived)
        #expect(item.status == BedManagement.CappedIsolationReviewStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCappedIsolationReview("code-764", name: "name-966")
        item.status = BedManagement.CappedIsolationReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedIsolationReviewStatus.`open`) }
    }
}
