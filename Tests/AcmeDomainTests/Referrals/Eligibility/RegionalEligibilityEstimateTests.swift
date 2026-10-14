@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilityEstimateTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newRegionalEligibilityEstimate("code-633", title: "title-532")
        #expect(item.status == Referrals.RegionalEligibilityEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newRegionalEligibilityEstimate("code-633", title: "title-532")
        try item.moveTo(Referrals.RegionalEligibilityEstimateStatus.resolved)
        #expect(item.status == Referrals.RegionalEligibilityEstimateStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newRegionalEligibilityEstimate("code-633", title: "title-532")
        item.status = Referrals.RegionalEligibilityEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalEligibilityEstimateStatus.`open`) }
    }
}
