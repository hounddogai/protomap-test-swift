@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRequestTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newEligibilityRequest("code-662", title: "title-516")
        #expect(item.status == Referrals.EligibilityRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newEligibilityRequest("code-662", title: "title-516")
        try item.moveTo(Referrals.EligibilityRequestStatus.completed)
        #expect(item.status == Referrals.EligibilityRequestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newEligibilityRequest("code-662", title: "title-516")
        item.status = Referrals.EligibilityRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityRequestStatus.planned) }
    }
}
