@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRuleTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newTransferRule("code-191", label: "label-752")
        #expect(item.status == BedManagement.TransferRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newTransferRule("code-191", label: "label-752")
        try item.moveTo(BedManagement.TransferRuleStatus.pending)
        #expect(item.status == BedManagement.TransferRuleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newTransferRule("code-191", label: "label-752")
        item.status = BedManagement.TransferRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferRuleStatus.draft) }
    }
}
