@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMappingTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStatementMapping("code-159", title: "title-945")
        #expect(item.status == RevenueCycle.StatementMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newStatementMapping("code-159", title: "title-945")
        try item.moveTo(RevenueCycle.StatementMappingStatus.published)
        #expect(item.status == RevenueCycle.StatementMappingStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStatementMapping("code-159", title: "title-945")
        item.status = RevenueCycle.StatementMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementMappingStatus.created) }
    }
}
