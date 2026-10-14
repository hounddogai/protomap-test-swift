@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedDenialTargetTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newCappedDenialTarget("code-840", name: "name-43")
        #expect(item.status == RevenueCycle.CappedDenialTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newCappedDenialTarget("code-840", name: "name-43")
        try item.moveTo(RevenueCycle.CappedDenialTargetStatus.ready)
        #expect(item.status == RevenueCycle.CappedDenialTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newCappedDenialTarget("code-840", name: "name-43")
        item.status = RevenueCycle.CappedDenialTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedDenialTargetStatus.idle) }
    }
}
