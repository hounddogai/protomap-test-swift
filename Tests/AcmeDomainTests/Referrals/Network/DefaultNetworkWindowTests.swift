@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkWindowTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newDefaultNetworkWindow("code-239", label: "label-53")
        #expect(item.status == Referrals.DefaultNetworkWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newDefaultNetworkWindow("code-239", label: "label-53")
        try item.moveTo(Referrals.DefaultNetworkWindowStatus.inReview)
        #expect(item.status == Referrals.DefaultNetworkWindowStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newDefaultNetworkWindow("code-239", label: "label-53")
        item.status = Referrals.DefaultNetworkWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultNetworkWindowStatus.`open`) }
    }
}
