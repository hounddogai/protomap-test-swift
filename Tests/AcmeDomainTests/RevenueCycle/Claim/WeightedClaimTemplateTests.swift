@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimTemplateTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newWeightedClaimTemplate("code-76", label: "label-394")
        #expect(item.status == RevenueCycle.WeightedClaimTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newWeightedClaimTemplate("code-76", label: "label-394")
        try item.moveTo(RevenueCycle.WeightedClaimTemplateStatus.done)
        #expect(item.status == RevenueCycle.WeightedClaimTemplateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newWeightedClaimTemplate("code-76", label: "label-394")
        item.status = RevenueCycle.WeightedClaimTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedClaimTemplateStatus.new) }
    }
}
