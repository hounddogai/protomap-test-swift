@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimGroupTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newWeightedClaimGroup("code-679", title: "title-200")
        #expect(item.status == RevenueCycle.WeightedClaimGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newWeightedClaimGroup("code-679", title: "title-200")
        try item.moveTo(RevenueCycle.WeightedClaimGroupStatus.validated)
        #expect(item.status == RevenueCycle.WeightedClaimGroupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newWeightedClaimGroup("code-679", title: "title-200")
        item.status = RevenueCycle.WeightedClaimGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedClaimGroupStatus.created) }
    }
}
