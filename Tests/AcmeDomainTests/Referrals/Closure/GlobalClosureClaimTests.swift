@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalClosureClaimTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newGlobalClosureClaim("code-719", title: "title-561")
        #expect(item.status == Referrals.GlobalClosureClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newGlobalClosureClaim("code-719", title: "title-561")
        try item.moveTo(Referrals.GlobalClosureClaimStatus.published)
        #expect(item.status == Referrals.GlobalClosureClaimStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newGlobalClosureClaim("code-719", title: "title-561")
        item.status = Referrals.GlobalClosureClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalClosureClaimStatus.created) }
    }
}
