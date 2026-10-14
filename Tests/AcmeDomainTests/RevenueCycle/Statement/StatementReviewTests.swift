@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementReviewTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStatementReview("code-663", name: "name-524")
        #expect(item.status == RevenueCycle.StatementReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newStatementReview("code-663", name: "name-524")
        try item.moveTo(RevenueCycle.StatementReviewStatus.published)
        #expect(item.status == RevenueCycle.StatementReviewStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStatementReview("code-663", name: "name-524")
        item.status = RevenueCycle.StatementReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementReviewStatus.created) }
    }
}
