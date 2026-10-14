@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceTargetTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newDefaultRemittanceTarget("code-143", name: "name-137")
        #expect(item.status == RevenueCycle.DefaultRemittanceTargetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newDefaultRemittanceTarget("code-143", name: "name-137")
        try item.moveTo(RevenueCycle.DefaultRemittanceTargetStatus.queued)
        #expect(item.status == RevenueCycle.DefaultRemittanceTargetStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newDefaultRemittanceTarget("code-143", name: "name-137")
        item.status = RevenueCycle.DefaultRemittanceTargetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultRemittanceTargetStatus.new) }
    }
}
