@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkOverrideTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newNetworkOverride("code-542", name: "name-201")
        #expect(item.status == Referrals.NetworkOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newNetworkOverride("code-542", name: "name-201")
        try item.moveTo(Referrals.NetworkOverrideStatus.resolved)
        #expect(item.status == Referrals.NetworkOverrideStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newNetworkOverride("code-542", name: "name-201")
        item.status = Referrals.NetworkOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkOverrideStatus.`open`) }
    }
}
