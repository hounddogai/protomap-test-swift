@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementGroupTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newPendingStatementGroup("code-814", title: "title-186")
        #expect(item.status == RevenueCycle.PendingStatementGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newPendingStatementGroup("code-814", title: "title-186")
        try item.moveTo(RevenueCycle.PendingStatementGroupStatus.approved)
        #expect(item.status == RevenueCycle.PendingStatementGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newPendingStatementGroup("code-814", title: "title-186")
        item.status = RevenueCycle.PendingStatementGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingStatementGroupStatus.proposed) }
    }
}
