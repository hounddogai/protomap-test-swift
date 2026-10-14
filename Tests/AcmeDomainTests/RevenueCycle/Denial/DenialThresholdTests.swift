@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialThresholdTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newDenialThreshold("code-784", title: "title-165")
        #expect(item.status == RevenueCycle.DenialThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newDenialThreshold("code-784", title: "title-165")
        try item.moveTo(RevenueCycle.DenialThresholdStatus.draining)
        #expect(item.status == RevenueCycle.DenialThresholdStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newDenialThreshold("code-784", title: "title-165")
        item.status = RevenueCycle.DenialThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialThresholdStatus.idle) }
    }
}
