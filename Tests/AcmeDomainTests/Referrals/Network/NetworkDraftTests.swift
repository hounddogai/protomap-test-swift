@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkDraftTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newNetworkDraft("code-773", name: "name-589")
        #expect(item.status == Referrals.NetworkDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newNetworkDraft("code-773", name: "name-589")
        try item.moveTo(Referrals.NetworkDraftStatus.resolved)
        #expect(item.status == Referrals.NetworkDraftStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newNetworkDraft("code-773", name: "name-589")
        item.status = Referrals.NetworkDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkDraftStatus.`open`) }
    }
}
