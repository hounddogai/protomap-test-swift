@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpMappingTests {
    @Test func startsInNew() throws {
        let item = Referrals.newAdaptiveFollowUpMapping("code-786", label: "label-632")
        #expect(item.status == Referrals.AdaptiveFollowUpMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newAdaptiveFollowUpMapping("code-786", label: "label-632")
        try item.moveTo(Referrals.AdaptiveFollowUpMappingStatus.running)
        #expect(item.status == Referrals.AdaptiveFollowUpMappingStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newAdaptiveFollowUpMapping("code-786", label: "label-632")
        item.status = Referrals.AdaptiveFollowUpMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveFollowUpMappingStatus.new) }
    }
}
