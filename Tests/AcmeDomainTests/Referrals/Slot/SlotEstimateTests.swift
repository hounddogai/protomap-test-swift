@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotEstimateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newSlotEstimate("code-766", title: "title-473")
        #expect(item.status == Referrals.SlotEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newSlotEstimate("code-766", title: "title-473")
        try item.moveTo(Referrals.SlotEstimateStatus.revoked)
        #expect(item.status == Referrals.SlotEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newSlotEstimate("code-766", title: "title-473")
        item.status = Referrals.SlotEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotEstimateStatus.requested) }
    }
}
