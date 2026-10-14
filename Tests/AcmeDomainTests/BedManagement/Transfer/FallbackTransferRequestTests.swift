@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferRequestTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newFallbackTransferRequest("code-141", title: "title-702")
        #expect(item.status == BedManagement.FallbackTransferRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newFallbackTransferRequest("code-141", title: "title-702")
        try item.moveTo(BedManagement.FallbackTransferRequestStatus.inReview)
        #expect(item.status == BedManagement.FallbackTransferRequestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newFallbackTransferRequest("code-141", title: "title-702")
        item.status = BedManagement.FallbackTransferRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackTransferRequestStatus.`open`) }
    }
}
