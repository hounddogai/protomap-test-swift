@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimAssignmentTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newWeightedClaimAssignment("code-152", title: "title-119")
        #expect(item.status == RevenueCycle.WeightedClaimAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newWeightedClaimAssignment("code-152", title: "title-119")
        try item.moveTo(RevenueCycle.WeightedClaimAssignmentStatus.granted)
        #expect(item.status == RevenueCycle.WeightedClaimAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newWeightedClaimAssignment("code-152", title: "title-119")
        item.status = RevenueCycle.WeightedClaimAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedClaimAssignmentStatus.requested) }
    }
}
