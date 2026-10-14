@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingTransferAgreementTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newPendingTransferAgreement("code-634", name: "name-826")
        #expect(item.status == BedManagement.PendingTransferAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newPendingTransferAgreement("code-634", name: "name-826")
        try item.moveTo(BedManagement.PendingTransferAgreementStatus.suspended)
        #expect(item.status == BedManagement.PendingTransferAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newPendingTransferAgreement("code-634", name: "name-826")
        item.status = BedManagement.PendingTransferAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingTransferAgreementStatus.draft) }
    }
}
