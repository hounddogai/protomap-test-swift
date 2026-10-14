@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkEntryTests {
    @Test func startsInNew() throws {
        let item = Referrals.newNetworkEntry("code-270", name: "name-155")
        #expect(item.status == Referrals.NetworkEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newNetworkEntry("code-270", name: "name-155")
        try item.moveTo(Referrals.NetworkEntryStatus.running)
        #expect(item.status == Referrals.NetworkEntryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newNetworkEntry("code-270", name: "name-155")
        item.status = Referrals.NetworkEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkEntryStatus.new) }
    }
}
