@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkGroupTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newGlobalNetworkGroup("code-712", label: "label-838")
        #expect(item.status == Referrals.GlobalNetworkGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newGlobalNetworkGroup("code-712", label: "label-838")
        try item.moveTo(Referrals.GlobalNetworkGroupStatus.inReview)
        #expect(item.status == Referrals.GlobalNetworkGroupStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newGlobalNetworkGroup("code-712", label: "label-838")
        item.status = Referrals.GlobalNetworkGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalNetworkGroupStatus.`open`) }
    }
}
