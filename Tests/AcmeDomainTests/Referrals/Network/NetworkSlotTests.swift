@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkSlotTests {
    @Test func startsInNew() throws {
        let item = Referrals.newNetworkSlot("code-565", label: "label-41")
        #expect(item.status == Referrals.NetworkSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newNetworkSlot("code-565", label: "label-41")
        try item.moveTo(Referrals.NetworkSlotStatus.done)
        #expect(item.status == Referrals.NetworkSlotStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newNetworkSlot("code-565", label: "label-41")
        item.status = Referrals.NetworkSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkSlotStatus.new) }
    }
}
