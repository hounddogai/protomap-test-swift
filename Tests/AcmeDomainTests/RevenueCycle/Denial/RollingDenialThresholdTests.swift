@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingDenialThresholdTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRollingDenialThreshold("code-699", title: "title-610")
        #expect(item.status == RevenueCycle.RollingDenialThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newRollingDenialThreshold("code-699", title: "title-610")
        try item.moveTo(RevenueCycle.RollingDenialThresholdStatus.inProgress)
        #expect(item.status == RevenueCycle.RollingDenialThresholdStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRollingDenialThreshold("code-699", title: "title-610")
        item.status = RevenueCycle.RollingDenialThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingDenialThresholdStatus.planned) }
    }
}
