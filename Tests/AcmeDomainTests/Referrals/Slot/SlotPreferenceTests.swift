@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newSlotPreference("code-59", label: "label-631")
        #expect(item.status == Referrals.SlotPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newSlotPreference("code-59", label: "label-631")
        try item.moveTo(Referrals.SlotPreferenceStatus.ready)
        #expect(item.status == Referrals.SlotPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newSlotPreference("code-59", label: "label-631")
        item.status = Referrals.SlotPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotPreferenceStatus.idle) }
    }
}
