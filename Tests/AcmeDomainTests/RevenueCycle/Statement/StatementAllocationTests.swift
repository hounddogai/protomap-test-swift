@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAllocationTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStatementAllocation("code-423", label: "label-48")
        #expect(item.status == RevenueCycle.StatementAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newStatementAllocation("code-423", label: "label-48")
        try item.moveTo(RevenueCycle.StatementAllocationStatus.draining)
        #expect(item.status == RevenueCycle.StatementAllocationStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStatementAllocation("code-423", label: "label-48")
        item.status = RevenueCycle.StatementAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementAllocationStatus.idle) }
    }
}
