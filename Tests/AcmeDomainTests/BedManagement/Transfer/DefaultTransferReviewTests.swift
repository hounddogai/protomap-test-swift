@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferReviewTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newDefaultTransferReview("code-617", name: "name-483")
        #expect(item.status == BedManagement.DefaultTransferReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newDefaultTransferReview("code-617", name: "name-483")
        try item.moveTo(BedManagement.DefaultTransferReviewStatus.inReview)
        #expect(item.status == BedManagement.DefaultTransferReviewStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newDefaultTransferReview("code-617", name: "name-483")
        item.status = BedManagement.DefaultTransferReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultTransferReviewStatus.`open`) }
    }
}
