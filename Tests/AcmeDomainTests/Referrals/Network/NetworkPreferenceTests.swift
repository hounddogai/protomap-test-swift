@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPreferenceTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newNetworkPreference("code-806", label: "label-272")
        #expect(item.status == Referrals.NetworkPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newNetworkPreference("code-806", label: "label-272")
        try item.moveTo(Referrals.NetworkPreferenceStatus.granted)
        #expect(item.status == Referrals.NetworkPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newNetworkPreference("code-806", label: "label-272")
        item.status = Referrals.NetworkPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkPreferenceStatus.requested) }
    }
}
