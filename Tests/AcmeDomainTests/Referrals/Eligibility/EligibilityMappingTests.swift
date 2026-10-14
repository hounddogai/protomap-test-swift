@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMappingTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityMapping("code-7", name: "name-824")
        #expect(item.status == Referrals.EligibilityMappingStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newEligibilityMapping("code-7", name: "name-824")
        try item.moveTo(Referrals.EligibilityMappingStatus.queued)
        #expect(item.status == Referrals.EligibilityMappingStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityMapping("code-7", name: "name-824")
        item.status = Referrals.EligibilityMappingStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityMappingStatus.new) }
    }
}
