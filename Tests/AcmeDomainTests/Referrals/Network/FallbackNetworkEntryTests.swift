@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkEntryTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newFallbackNetworkEntry("code-363", label: "label-561")
        #expect(item.status == Referrals.FallbackNetworkEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newFallbackNetworkEntry("code-363", label: "label-561")
        try item.moveTo(Referrals.FallbackNetworkEntryStatus.published)
        #expect(item.status == Referrals.FallbackNetworkEntryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newFallbackNetworkEntry("code-363", label: "label-561")
        item.status = Referrals.FallbackNetworkEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackNetworkEntryStatus.created) }
    }
}
