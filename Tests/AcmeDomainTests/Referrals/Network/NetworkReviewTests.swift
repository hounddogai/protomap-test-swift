@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkReviewTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newNetworkReview("code-713", name: "name-769")
        #expect(item.status == Referrals.NetworkReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newNetworkReview("code-713", name: "name-769")
        try item.moveTo(Referrals.NetworkReviewStatus.retired)
        #expect(item.status == Referrals.NetworkReviewStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newNetworkReview("code-713", name: "name-769")
        item.status = Referrals.NetworkReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkReviewStatus.created) }
    }
}
