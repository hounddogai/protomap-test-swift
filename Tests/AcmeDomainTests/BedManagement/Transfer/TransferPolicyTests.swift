@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPolicyTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTransferPolicy("code-811", name: "name-370")
        #expect(item.status == BedManagement.TransferPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newTransferPolicy("code-811", name: "name-370")
        try item.moveTo(BedManagement.TransferPolicyStatus.inReview)
        #expect(item.status == BedManagement.TransferPolicyStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTransferPolicy("code-811", name: "name-370")
        item.status = BedManagement.TransferPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferPolicyStatus.`open`) }
    }
}
