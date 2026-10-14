@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkBundleTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newRegionalNetworkBundle("code-94", label: "label-913")
        #expect(item.status == Referrals.RegionalNetworkBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newRegionalNetworkBundle("code-94", label: "label-913")
        try item.moveTo(Referrals.RegionalNetworkBundleStatus.expired)
        #expect(item.status == Referrals.RegionalNetworkBundleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newRegionalNetworkBundle("code-94", label: "label-913")
        item.status = Referrals.RegionalNetworkBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalNetworkBundleStatus.requested) }
    }
}
