@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackStatementAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newFallbackStatementAssignment("code-123", title: "title-832")
        #expect(item.status == RevenueCycle.FallbackStatementAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newFallbackStatementAssignment("code-123", title: "title-832")
        try item.moveTo(RevenueCycle.FallbackStatementAssignmentStatus.completed)
        #expect(item.status == RevenueCycle.FallbackStatementAssignmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newFallbackStatementAssignment("code-123", title: "title-832")
        item.status = RevenueCycle.FallbackStatementAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackStatementAssignmentStatus.planned) }
    }
}
