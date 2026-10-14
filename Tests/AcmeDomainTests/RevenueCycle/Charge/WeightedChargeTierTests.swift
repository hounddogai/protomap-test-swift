@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeTierTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newWeightedChargeTier("code-875", name: "name-966")
        #expect(item.status == RevenueCycle.WeightedChargeTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newWeightedChargeTier("code-875", name: "name-966")
        try item.moveTo(RevenueCycle.WeightedChargeTierStatus.published)
        #expect(item.status == RevenueCycle.WeightedChargeTierStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newWeightedChargeTier("code-875", name: "name-966")
        item.status = RevenueCycle.WeightedChargeTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedChargeTierStatus.created) }
    }
}
