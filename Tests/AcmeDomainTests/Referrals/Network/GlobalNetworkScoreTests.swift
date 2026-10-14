@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkScoreTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newGlobalNetworkScore("code-834", label: "label-972")
        #expect(item.status == Referrals.GlobalNetworkScoreStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newGlobalNetworkScore("code-834", label: "label-972")
        try item.moveTo(Referrals.GlobalNetworkScoreStatus.warming)
        #expect(item.status == Referrals.GlobalNetworkScoreStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newGlobalNetworkScore("code-834", label: "label-972")
        item.status = Referrals.GlobalNetworkScoreStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalNetworkScoreStatus.idle) }
    }
}
