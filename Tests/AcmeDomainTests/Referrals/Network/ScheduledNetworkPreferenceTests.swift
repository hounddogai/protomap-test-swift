@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkPreferenceTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newScheduledNetworkPreference("code-337", name: "name-221")
        #expect(item.status == Referrals.ScheduledNetworkPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newScheduledNetworkPreference("code-337", name: "name-221")
        try item.moveTo(Referrals.ScheduledNetworkPreferenceStatus.validated)
        #expect(item.status == Referrals.ScheduledNetworkPreferenceStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newScheduledNetworkPreference("code-337", name: "name-221")
        item.status = Referrals.ScheduledNetworkPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledNetworkPreferenceStatus.created) }
    }
}
