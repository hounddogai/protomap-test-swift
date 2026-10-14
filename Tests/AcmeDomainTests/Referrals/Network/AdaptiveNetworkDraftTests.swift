@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkDraftTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newAdaptiveNetworkDraft("code-891", name: "name-541")
        #expect(item.status == Referrals.AdaptiveNetworkDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newAdaptiveNetworkDraft("code-891", name: "name-541")
        try item.moveTo(Referrals.AdaptiveNetworkDraftStatus.published)
        #expect(item.status == Referrals.AdaptiveNetworkDraftStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newAdaptiveNetworkDraft("code-891", name: "name-541")
        item.status = Referrals.AdaptiveNetworkDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveNetworkDraftStatus.created) }
    }
}
