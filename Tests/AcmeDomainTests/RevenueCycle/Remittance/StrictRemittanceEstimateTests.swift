@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictRemittanceEstimateTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStrictRemittanceEstimate("code-850", name: "name-699")
        #expect(item.status == RevenueCycle.StrictRemittanceEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newStrictRemittanceEstimate("code-850", name: "name-699")
        try item.moveTo(RevenueCycle.StrictRemittanceEstimateStatus.suspended)
        #expect(item.status == RevenueCycle.StrictRemittanceEstimateStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStrictRemittanceEstimate("code-850", name: "name-699")
        item.status = RevenueCycle.StrictRemittanceEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictRemittanceEstimateStatus.draft) }
    }
}
