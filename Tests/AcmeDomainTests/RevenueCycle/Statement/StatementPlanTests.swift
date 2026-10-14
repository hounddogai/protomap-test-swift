@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPlanTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newStatementPlan("code-415", name: "name-839")
        #expect(item.status == RevenueCycle.StatementPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newStatementPlan("code-415", name: "name-839")
        try item.moveTo(RevenueCycle.StatementPlanStatus.inReview)
        #expect(item.status == RevenueCycle.StatementPlanStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newStatementPlan("code-415", name: "name-839")
        item.status = RevenueCycle.StatementPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementPlanStatus.`open`) }
    }
}
