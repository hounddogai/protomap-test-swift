@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientDenialTargetTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newLenientDenialTarget("code-36", label: "label-581")
        #expect(item.status == RevenueCycle.LenientDenialTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newLenientDenialTarget("code-36", label: "label-581")
        try item.moveTo(RevenueCycle.LenientDenialTargetStatus.draining)
        #expect(item.status == RevenueCycle.LenientDenialTargetStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newLenientDenialTarget("code-36", label: "label-581")
        item.status = RevenueCycle.LenientDenialTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientDenialTargetStatus.idle) }
    }
}
