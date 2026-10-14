@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralProfileTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newReferralProfile("code-80", label: "label-845")
        #expect(item.status == Referrals.ReferralProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newReferralProfile("code-80", label: "label-845")
        try item.moveTo(Referrals.ReferralProfileStatus.archived)
        #expect(item.status == Referrals.ReferralProfileStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newReferralProfile("code-80", label: "label-845")
        item.status = Referrals.ReferralProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralProfileStatus.`open`) }
    }
}
