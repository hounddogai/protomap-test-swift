@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningAgreementTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCleaningAgreement("code-164", name: "name-185")
        #expect(item.status == BedManagement.CleaningAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newCleaningAgreement("code-164", name: "name-185")
        try item.moveTo(BedManagement.CleaningAgreementStatus.suspended)
        #expect(item.status == BedManagement.CleaningAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCleaningAgreement("code-164", name: "name-185")
        item.status = BedManagement.CleaningAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningAgreementStatus.draft) }
    }
}
