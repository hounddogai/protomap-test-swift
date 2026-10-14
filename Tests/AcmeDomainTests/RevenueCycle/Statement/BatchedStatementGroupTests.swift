@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementGroupTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newBatchedStatementGroup("code-987", title: "title-697")
        #expect(item.status == RevenueCycle.BatchedStatementGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newBatchedStatementGroup("code-987", title: "title-697")
        try item.moveTo(RevenueCycle.BatchedStatementGroupStatus.archived)
        #expect(item.status == RevenueCycle.BatchedStatementGroupStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newBatchedStatementGroup("code-987", title: "title-697")
        item.status = RevenueCycle.BatchedStatementGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedStatementGroupStatus.`open`) }
    }
}
