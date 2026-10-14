@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimCheckpointTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStrictClaimCheckpoint("code-474", title: "title-728")
        #expect(item.status == RevenueCycle.StrictClaimCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newStrictClaimCheckpoint("code-474", title: "title-728")
        try item.moveTo(RevenueCycle.StrictClaimCheckpointStatus.stopped)
        #expect(item.status == RevenueCycle.StrictClaimCheckpointStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStrictClaimCheckpoint("code-474", title: "title-728")
        item.status = RevenueCycle.StrictClaimCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictClaimCheckpointStatus.idle) }
    }
}
