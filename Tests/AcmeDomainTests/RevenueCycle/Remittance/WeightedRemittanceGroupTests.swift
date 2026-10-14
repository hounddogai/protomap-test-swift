@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedRemittanceGroupTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newWeightedRemittanceGroup("code-754", label: "label-619")
        #expect(item.status == RevenueCycle.WeightedRemittanceGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newWeightedRemittanceGroup("code-754", label: "label-619")
        try item.moveTo(RevenueCycle.WeightedRemittanceGroupStatus.suspended)
        #expect(item.status == RevenueCycle.WeightedRemittanceGroupStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newWeightedRemittanceGroup("code-754", label: "label-619")
        item.status = RevenueCycle.WeightedRemittanceGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedRemittanceGroupStatus.draft) }
    }
}
