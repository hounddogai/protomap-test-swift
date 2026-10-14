@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementExceptionTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newLegacyStatementException("code-940", title: "title-834")
        #expect(item.status == RevenueCycle.LegacyStatementExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newLegacyStatementException("code-940", title: "title-834")
        try item.moveTo(RevenueCycle.LegacyStatementExceptionStatus.inReview)
        #expect(item.status == RevenueCycle.LegacyStatementExceptionStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newLegacyStatementException("code-940", title: "title-834")
        item.status = RevenueCycle.LegacyStatementExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyStatementExceptionStatus.`open`) }
    }
}
