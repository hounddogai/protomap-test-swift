@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkDraftTests {
    @Test func startsInNew() throws {
        let item = Referrals.newScheduledNetworkDraft("code-874", name: "name-800")
        #expect(item.status == Referrals.ScheduledNetworkDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newScheduledNetworkDraft("code-874", name: "name-800")
        try item.moveTo(Referrals.ScheduledNetworkDraftStatus.queued)
        #expect(item.status == Referrals.ScheduledNetworkDraftStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newScheduledNetworkDraft("code-874", name: "name-800")
        item.status = Referrals.ScheduledNetworkDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledNetworkDraftStatus.new) }
    }
}
