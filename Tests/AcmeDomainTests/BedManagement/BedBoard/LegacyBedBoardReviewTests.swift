@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyBedBoardReviewTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newLegacyBedBoardReview("code-475", name: "name-15")
        #expect(item.status == BedManagement.LegacyBedBoardReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newLegacyBedBoardReview("code-475", name: "name-15")
        try item.moveTo(BedManagement.LegacyBedBoardReviewStatus.revoked)
        #expect(item.status == BedManagement.LegacyBedBoardReviewStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newLegacyBedBoardReview("code-475", name: "name-15")
        item.status = BedManagement.LegacyBedBoardReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyBedBoardReviewStatus.requested) }
    }
}
