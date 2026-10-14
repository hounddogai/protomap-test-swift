@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedSlotLedgerTests {
    @Test func startsInNew() throws {
        let item = Referrals.newWeightedSlotLedger("code-363", label: "label-801")
        #expect(item.status == Referrals.WeightedSlotLedgerStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newWeightedSlotLedger("code-363", label: "label-801")
        try item.moveTo(Referrals.WeightedSlotLedgerStatus.failed)
        #expect(item.status == Referrals.WeightedSlotLedgerStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newWeightedSlotLedger("code-363", label: "label-801")
        item.status = Referrals.WeightedSlotLedgerStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedSlotLedgerStatus.new) }
    }
}
