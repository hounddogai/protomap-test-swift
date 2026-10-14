@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeThresholdTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newWeightedChargeThreshold("code-879", name: "name-110")
        #expect(item.status == RevenueCycle.WeightedChargeThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newWeightedChargeThreshold("code-879", name: "name-110")
        try item.moveTo(RevenueCycle.WeightedChargeThresholdStatus.resolved)
        #expect(item.status == RevenueCycle.WeightedChargeThresholdStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newWeightedChargeThreshold("code-879", name: "name-110")
        item.status = RevenueCycle.WeightedChargeThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedChargeThresholdStatus.`open`) }
    }
}
