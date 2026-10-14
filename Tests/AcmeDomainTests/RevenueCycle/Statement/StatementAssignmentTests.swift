@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAssignmentTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newStatementAssignment("code-873", label: "label-768")
        #expect(item.status == RevenueCycle.StatementAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newStatementAssignment("code-873", label: "label-768")
        try item.moveTo(RevenueCycle.StatementAssignmentStatus.active)
        #expect(item.status == RevenueCycle.StatementAssignmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newStatementAssignment("code-873", label: "label-768")
        item.status = RevenueCycle.StatementAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementAssignmentStatus.draft) }
    }
}
