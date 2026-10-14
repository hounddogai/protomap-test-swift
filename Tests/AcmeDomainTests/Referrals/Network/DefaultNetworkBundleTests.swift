@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkBundleTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newDefaultNetworkBundle("code-100", title: "title-548")
        #expect(item.status == Referrals.DefaultNetworkBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newDefaultNetworkBundle("code-100", title: "title-548")
        try item.moveTo(Referrals.DefaultNetworkBundleStatus.validated)
        #expect(item.status == Referrals.DefaultNetworkBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newDefaultNetworkBundle("code-100", title: "title-548")
        item.status = Referrals.DefaultNetworkBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultNetworkBundleStatus.created) }
    }
}
