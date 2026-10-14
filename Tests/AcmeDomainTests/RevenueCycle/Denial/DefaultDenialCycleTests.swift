@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultDenialCycleTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDefaultDenialCycle("code-663", title: "title-806")
        #expect(item.status == RevenueCycle.DefaultDenialCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newDefaultDenialCycle("code-663", title: "title-806")
        try item.moveTo(RevenueCycle.DefaultDenialCycleStatus.draining)
        #expect(item.status == RevenueCycle.DefaultDenialCycleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDefaultDenialCycle("code-663", title: "title-806")
        item.status = RevenueCycle.DefaultDenialCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultDenialCycleStatus.idle) }
    }
}
