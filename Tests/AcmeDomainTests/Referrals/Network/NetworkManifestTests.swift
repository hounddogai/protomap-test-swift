@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkManifestTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkManifest("code-899", label: "label-177")
        #expect(item.status == Referrals.NetworkManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newNetworkManifest("code-899", label: "label-177")
        try item.moveTo(Referrals.NetworkManifestStatus.suspended)
        #expect(item.status == Referrals.NetworkManifestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkManifest("code-899", label: "label-177")
        item.status = Referrals.NetworkManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkManifestStatus.draft) }
    }
}
