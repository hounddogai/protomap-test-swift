@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedDenialGroupTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newWeightedDenialGroup("code-375", name: "name-345")
        #expect(item.status == RevenueCycle.WeightedDenialGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newWeightedDenialGroup("code-375", name: "name-345")
        try item.moveTo(RevenueCycle.WeightedDenialGroupStatus.ready)
        #expect(item.status == RevenueCycle.WeightedDenialGroupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newWeightedDenialGroup("code-375", name: "name-345")
        item.status = RevenueCycle.WeightedDenialGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedDenialGroupStatus.idle) }
    }
}
