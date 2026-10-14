@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementThresholdTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAdaptiveStatementThreshold("code-270", label: "label-70")
        #expect(item.status == RevenueCycle.AdaptiveStatementThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newAdaptiveStatementThreshold("code-270", label: "label-70")
        try item.moveTo(RevenueCycle.AdaptiveStatementThresholdStatus.done)
        #expect(item.status == RevenueCycle.AdaptiveStatementThresholdStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAdaptiveStatementThreshold("code-270", label: "label-70")
        item.status = RevenueCycle.AdaptiveStatementThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveStatementThresholdStatus.new) }
    }
}
