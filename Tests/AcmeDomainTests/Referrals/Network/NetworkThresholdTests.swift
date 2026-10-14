@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkThresholdTests {
    @Test func startsInNew() throws {
        let item = Referrals.newNetworkThreshold("code-927", label: "label-4")
        #expect(item.status == Referrals.NetworkThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newNetworkThreshold("code-927", label: "label-4")
        try item.moveTo(Referrals.NetworkThresholdStatus.done)
        #expect(item.status == Referrals.NetworkThresholdStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newNetworkThreshold("code-927", label: "label-4")
        item.status = Referrals.NetworkThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkThresholdStatus.new) }
    }
}
