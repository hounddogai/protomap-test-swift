@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralProfileTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newSeasonalReferralProfile("code-21", label: "label-985")
        #expect(item.status == Referrals.SeasonalReferralProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newSeasonalReferralProfile("code-21", label: "label-985")
        try item.moveTo(Referrals.SeasonalReferralProfileStatus.granted)
        #expect(item.status == Referrals.SeasonalReferralProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newSeasonalReferralProfile("code-21", label: "label-985")
        item.status = Referrals.SeasonalReferralProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalReferralProfileStatus.requested) }
    }
}
