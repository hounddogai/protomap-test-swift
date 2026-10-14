@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedSlotProfileTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newCappedSlotProfile("code-687", title: "title-700")
        #expect(item.status == Referrals.CappedSlotProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newCappedSlotProfile("code-687", title: "title-700")
        try item.moveTo(Referrals.CappedSlotProfileStatus.warming)
        #expect(item.status == Referrals.CappedSlotProfileStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newCappedSlotProfile("code-687", title: "title-700")
        item.status = Referrals.CappedSlotProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedSlotProfileStatus.idle) }
    }
}
