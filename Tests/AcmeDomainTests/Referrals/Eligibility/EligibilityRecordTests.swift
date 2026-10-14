@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRecordTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newEligibilityRecord("code-558", title: "title-283")
        #expect(item.status == Referrals.EligibilityRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newEligibilityRecord("code-558", title: "title-283")
        try item.moveTo(Referrals.EligibilityRecordStatus.approved)
        #expect(item.status == Referrals.EligibilityRecordStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newEligibilityRecord("code-558", title: "title-283")
        item.status = Referrals.EligibilityRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityRecordStatus.proposed) }
    }
}
