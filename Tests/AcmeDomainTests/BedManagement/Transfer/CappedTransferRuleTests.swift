@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedTransferRuleTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCappedTransferRule("code-675", label: "label-677")
        #expect(item.status == BedManagement.CappedTransferRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newCappedTransferRule("code-675", label: "label-677")
        try item.moveTo(BedManagement.CappedTransferRuleStatus.ready)
        #expect(item.status == BedManagement.CappedTransferRuleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCappedTransferRule("code-675", label: "label-677")
        item.status = BedManagement.CappedTransferRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedTransferRuleStatus.idle) }
    }
}
