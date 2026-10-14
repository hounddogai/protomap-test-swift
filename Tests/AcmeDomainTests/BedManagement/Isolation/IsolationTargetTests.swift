@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTargetTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newIsolationTarget("code-882", label: "label-711")
        #expect(item.status == BedManagement.IsolationTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newIsolationTarget("code-882", label: "label-711")
        try item.moveTo(BedManagement.IsolationTargetStatus.approved)
        #expect(item.status == BedManagement.IsolationTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newIsolationTarget("code-882", label: "label-711")
        item.status = BedManagement.IsolationTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationTargetStatus.proposed) }
    }
}
