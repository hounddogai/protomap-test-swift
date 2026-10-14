@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceSnapshotTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAdaptiveRemittanceSnapshot("code-629", name: "name-506")
        #expect(item.status == RevenueCycle.AdaptiveRemittanceSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newAdaptiveRemittanceSnapshot("code-629", name: "name-506")
        try item.moveTo(RevenueCycle.AdaptiveRemittanceSnapshotStatus.queued)
        #expect(item.status == RevenueCycle.AdaptiveRemittanceSnapshotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAdaptiveRemittanceSnapshot("code-629", name: "name-506")
        item.status = RevenueCycle.AdaptiveRemittanceSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveRemittanceSnapshotStatus.new) }
    }
}
