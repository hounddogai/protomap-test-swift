@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotQuotaTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newSlotQuota("code-480", title: "title-671")
        #expect(item.status == Referrals.SlotQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newSlotQuota("code-480", title: "title-671")
        try item.moveTo(Referrals.SlotQuotaStatus.ready)
        #expect(item.status == Referrals.SlotQuotaStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newSlotQuota("code-480", title: "title-671")
        item.status = Referrals.SlotQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotQuotaStatus.idle) }
    }
}
