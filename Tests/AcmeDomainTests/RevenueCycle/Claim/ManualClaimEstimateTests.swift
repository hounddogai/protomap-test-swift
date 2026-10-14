@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualClaimEstimateTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newManualClaimEstimate("code-271", name: "name-723")
        #expect(item.status == RevenueCycle.ManualClaimEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newManualClaimEstimate("code-271", name: "name-723")
        try item.moveTo(RevenueCycle.ManualClaimEstimateStatus.done)
        #expect(item.status == RevenueCycle.ManualClaimEstimateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newManualClaimEstimate("code-271", name: "name-723")
        item.status = RevenueCycle.ManualClaimEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualClaimEstimateStatus.new) }
    }
}
