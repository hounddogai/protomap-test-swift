@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAgreementTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newTransferAgreement("code-732", label: "label-639")
        #expect(item.status == BedManagement.TransferAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newTransferAgreement("code-732", label: "label-639")
        try item.moveTo(BedManagement.TransferAgreementStatus.approved)
        #expect(item.status == BedManagement.TransferAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newTransferAgreement("code-732", label: "label-639")
        item.status = BedManagement.TransferAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferAgreementStatus.proposed) }
    }
}
