@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargePolicyTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newWeightedChargePolicy("code-50", label: "label-680")
        #expect(item.status == RevenueCycle.WeightedChargePolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newWeightedChargePolicy("code-50", label: "label-680")
        try item.moveTo(RevenueCycle.WeightedChargePolicyStatus.running)
        #expect(item.status == RevenueCycle.WeightedChargePolicyStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newWeightedChargePolicy("code-50", label: "label-680")
        item.status = RevenueCycle.WeightedChargePolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedChargePolicyStatus.new) }
    }
}
