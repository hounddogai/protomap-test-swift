@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningLedgerTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newFallbackCleaningLedger("code-499", label: "label-498")
        #expect(item.status == BedManagement.FallbackCleaningLedgerStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newFallbackCleaningLedger("code-499", label: "label-498")
        try item.moveTo(BedManagement.FallbackCleaningLedgerStatus.expired)
        #expect(item.status == BedManagement.FallbackCleaningLedgerStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newFallbackCleaningLedger("code-499", label: "label-498")
        item.status = BedManagement.FallbackCleaningLedgerStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackCleaningLedgerStatus.requested) }
    }
}
