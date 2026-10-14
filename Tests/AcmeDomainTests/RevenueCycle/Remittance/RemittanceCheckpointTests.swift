@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceCheckpointTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceCheckpoint("code-24", label: "label-346")
        #expect(item.status == RevenueCycle.RemittanceCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newRemittanceCheckpoint("code-24", label: "label-346")
        try item.moveTo(RevenueCycle.RemittanceCheckpointStatus.ready)
        #expect(item.status == RevenueCycle.RemittanceCheckpointStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceCheckpoint("code-24", label: "label-346")
        item.status = RevenueCycle.RemittanceCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceCheckpointStatus.idle) }
    }
}
