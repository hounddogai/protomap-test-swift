@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralRequestTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newReferralRequest("code-61", name: "name-936")
        #expect(item.status == Referrals.ReferralRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newReferralRequest("code-61", name: "name-936")
        try item.moveTo(Referrals.ReferralRequestStatus.warming)
        #expect(item.status == Referrals.ReferralRequestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newReferralRequest("code-61", name: "name-936")
        item.status = Referrals.ReferralRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralRequestStatus.idle) }
    }
}
