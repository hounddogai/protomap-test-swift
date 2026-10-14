@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferClaimTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBatchedTransferClaim("code-244", name: "name-119")
        #expect(item.status == BedManagement.BatchedTransferClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newBatchedTransferClaim("code-244", name: "name-119")
        try item.moveTo(BedManagement.BatchedTransferClaimStatus.inReview)
        #expect(item.status == BedManagement.BatchedTransferClaimStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBatchedTransferClaim("code-244", name: "name-119")
        item.status = BedManagement.BatchedTransferClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedTransferClaimStatus.`open`) }
    }
}
