@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalClosureClaimTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newRegionalClosureClaim("code-110", title: "title-202")
        #expect(item.status == Referrals.RegionalClosureClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Referrals.newRegionalClosureClaim("code-110", title: "title-202")
        try item.moveTo(Referrals.RegionalClosureClaimStatus.archived)
        #expect(item.status == Referrals.RegionalClosureClaimStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newRegionalClosureClaim("code-110", title: "title-202")
        item.status = Referrals.RegionalClosureClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalClosureClaimStatus.`open`) }
    }
}
