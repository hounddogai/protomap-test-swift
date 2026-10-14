@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeBatchTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newFallbackChargeBatch("code-193", name: "name-25")
        #expect(item.status == RevenueCycle.FallbackChargeBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newFallbackChargeBatch("code-193", name: "name-25")
        try item.moveTo(RevenueCycle.FallbackChargeBatchStatus.warming)
        #expect(item.status == RevenueCycle.FallbackChargeBatchStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newFallbackChargeBatch("code-193", name: "name-25")
        item.status = RevenueCycle.FallbackChargeBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackChargeBatchStatus.idle) }
    }
}
