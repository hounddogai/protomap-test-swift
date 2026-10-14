@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkBundleTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newScheduledNetworkBundle("code-539", label: "label-764")
        #expect(item.status == Referrals.ScheduledNetworkBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newScheduledNetworkBundle("code-539", label: "label-764")
        try item.moveTo(Referrals.ScheduledNetworkBundleStatus.draining)
        #expect(item.status == Referrals.ScheduledNetworkBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newScheduledNetworkBundle("code-539", label: "label-764")
        item.status = Referrals.ScheduledNetworkBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledNetworkBundleStatus.idle) }
    }
}
