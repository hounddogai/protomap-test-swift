@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralMappingTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newSeasonalReferralMapping("code-526", label: "label-297")
        #expect(item.status == Referrals.SeasonalReferralMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newSeasonalReferralMapping("code-526", label: "label-297")
        try item.moveTo(Referrals.SeasonalReferralMappingStatus.suspended)
        #expect(item.status == Referrals.SeasonalReferralMappingStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newSeasonalReferralMapping("code-526", label: "label-297")
        item.status = Referrals.SeasonalReferralMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalReferralMappingStatus.draft) }
    }
}
