@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotBundleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSlotBundle("code-584", label: "label-229")
        #expect(item.status == Referrals.SlotBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newSlotBundle("code-584", label: "label-229")
        try item.moveTo(Referrals.SlotBundleStatus.failed)
        #expect(item.status == Referrals.SlotBundleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSlotBundle("code-584", label: "label-229")
        item.status = Referrals.SlotBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotBundleStatus.new) }
    }
}
