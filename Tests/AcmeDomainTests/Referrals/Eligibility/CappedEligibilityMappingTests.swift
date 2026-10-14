@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityMappingTests {
    @Test func startsInNew() throws {
        let item = Referrals.newCappedEligibilityMapping("code-145", title: "title-858")
        #expect(item.status == Referrals.CappedEligibilityMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newCappedEligibilityMapping("code-145", title: "title-858")
        try item.moveTo(Referrals.CappedEligibilityMappingStatus.done)
        #expect(item.status == Referrals.CappedEligibilityMappingStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newCappedEligibilityMapping("code-145", title: "title-858")
        item.status = Referrals.CappedEligibilityMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedEligibilityMappingStatus.new) }
    }
}
