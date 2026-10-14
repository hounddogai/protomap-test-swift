@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceCycleTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceCycle("code-940", name: "name-521")
        #expect(item.status == RevenueCycle.RemittanceCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newRemittanceCycle("code-940", name: "name-521")
        try item.moveTo(RevenueCycle.RemittanceCycleStatus.draining)
        #expect(item.status == RevenueCycle.RemittanceCycleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceCycle("code-940", name: "name-521")
        item.status = RevenueCycle.RemittanceCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceCycleStatus.idle) }
    }
}
