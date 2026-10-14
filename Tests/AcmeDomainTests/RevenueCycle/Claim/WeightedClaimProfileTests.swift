@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimProfileTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newWeightedClaimProfile("code-147", label: "label-734")
        #expect(item.status == RevenueCycle.WeightedClaimProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newWeightedClaimProfile("code-147", label: "label-734")
        try item.moveTo(RevenueCycle.WeightedClaimProfileStatus.cancelled)
        #expect(item.status == RevenueCycle.WeightedClaimProfileStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newWeightedClaimProfile("code-147", label: "label-734")
        item.status = RevenueCycle.WeightedClaimProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedClaimProfileStatus.planned) }
    }
}
