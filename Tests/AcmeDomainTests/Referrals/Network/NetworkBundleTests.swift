@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkBundleTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkBundle("code-516", label: "label-393")
        #expect(item.status == Referrals.NetworkBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newNetworkBundle("code-516", label: "label-393")
        try item.moveTo(Referrals.NetworkBundleStatus.active)
        #expect(item.status == Referrals.NetworkBundleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkBundle("code-516", label: "label-393")
        item.status = Referrals.NetworkBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkBundleStatus.draft) }
    }
}
