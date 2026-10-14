@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryNetworkTierTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newPrimaryNetworkTier("code-771", name: "name-172")
        #expect(item.status == Referrals.PrimaryNetworkTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newPrimaryNetworkTier("code-771", name: "name-172")
        try item.moveTo(Referrals.PrimaryNetworkTierStatus.validated)
        #expect(item.status == Referrals.PrimaryNetworkTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newPrimaryNetworkTier("code-771", name: "name-172")
        item.status = Referrals.PrimaryNetworkTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryNetworkTierStatus.created) }
    }
}
