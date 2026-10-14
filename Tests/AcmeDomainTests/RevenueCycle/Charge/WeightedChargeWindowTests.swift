@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeWindowTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newWeightedChargeWindow("code-17", title: "title-390")
        #expect(item.status == RevenueCycle.WeightedChargeWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newWeightedChargeWindow("code-17", title: "title-390")
        try item.moveTo(RevenueCycle.WeightedChargeWindowStatus.active)
        #expect(item.status == RevenueCycle.WeightedChargeWindowStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newWeightedChargeWindow("code-17", title: "title-390")
        item.status = RevenueCycle.WeightedChargeWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedChargeWindowStatus.draft) }
    }
}
