@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedSlotBundleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newWeightedSlotBundle("code-622", title: "title-383")
        #expect(item.status == Referrals.WeightedSlotBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newWeightedSlotBundle("code-622", title: "title-383")
        try item.moveTo(Referrals.WeightedSlotBundleStatus.queued)
        #expect(item.status == Referrals.WeightedSlotBundleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newWeightedSlotBundle("code-622", title: "title-383")
        item.status = Referrals.WeightedSlotBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedSlotBundleStatus.new) }
    }
}
