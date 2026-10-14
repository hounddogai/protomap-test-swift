@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedChargeAssignmentTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newCappedChargeAssignment("code-274", label: "label-121")
        #expect(item.status == RevenueCycle.CappedChargeAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newCappedChargeAssignment("code-274", label: "label-121")
        try item.moveTo(RevenueCycle.CappedChargeAssignmentStatus.revoked)
        #expect(item.status == RevenueCycle.CappedChargeAssignmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newCappedChargeAssignment("code-274", label: "label-121")
        item.status = RevenueCycle.CappedChargeAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedChargeAssignmentStatus.requested) }
    }
}
