@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementThresholdTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newStatementThreshold("code-371", title: "title-993")
        #expect(item.status == RevenueCycle.StatementThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newStatementThreshold("code-371", title: "title-993")
        try item.moveTo(RevenueCycle.StatementThresholdStatus.reopened)
        #expect(item.status == RevenueCycle.StatementThresholdStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newStatementThreshold("code-371", title: "title-993")
        item.status = RevenueCycle.StatementThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementThresholdStatus.`open`) }
    }
}
