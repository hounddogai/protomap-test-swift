@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferReviewTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTransferReview("code-6", name: "name-192")
        #expect(item.status == BedManagement.TransferReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newTransferReview("code-6", name: "name-192")
        try item.moveTo(BedManagement.TransferReviewStatus.inReview)
        #expect(item.status == BedManagement.TransferReviewStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTransferReview("code-6", name: "name-192")
        item.status = BedManagement.TransferReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferReviewStatus.`open`) }
    }
}
