@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalRemittanceAssignmentTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newGlobalRemittanceAssignment("code-9", label: "label-27")
        #expect(item.status == RevenueCycle.GlobalRemittanceAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newGlobalRemittanceAssignment("code-9", label: "label-27")
        try item.moveTo(RevenueCycle.GlobalRemittanceAssignmentStatus.approved)
        #expect(item.status == RevenueCycle.GlobalRemittanceAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newGlobalRemittanceAssignment("code-9", label: "label-27")
        item.status = RevenueCycle.GlobalRemittanceAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalRemittanceAssignmentStatus.proposed) }
    }
}
