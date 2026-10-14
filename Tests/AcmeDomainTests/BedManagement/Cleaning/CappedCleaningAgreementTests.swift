@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningAgreementTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCappedCleaningAgreement("code-120", label: "label-633")
        #expect(item.status == BedManagement.CappedCleaningAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newCappedCleaningAgreement("code-120", label: "label-633")
        try item.moveTo(BedManagement.CappedCleaningAgreementStatus.pending)
        #expect(item.status == BedManagement.CappedCleaningAgreementStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCappedCleaningAgreement("code-120", label: "label-633")
        item.status = BedManagement.CappedCleaningAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedCleaningAgreementStatus.draft) }
    }
}
