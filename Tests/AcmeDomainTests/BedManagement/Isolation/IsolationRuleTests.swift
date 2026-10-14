@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRuleTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newIsolationRule("code-124", title: "title-78")
        #expect(item.status == BedManagement.IsolationRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newIsolationRule("code-124", title: "title-78")
        try item.moveTo(BedManagement.IsolationRuleStatus.approved)
        #expect(item.status == BedManagement.IsolationRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newIsolationRule("code-124", title: "title-78")
        item.status = BedManagement.IsolationRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationRuleStatus.proposed) }
    }
}
