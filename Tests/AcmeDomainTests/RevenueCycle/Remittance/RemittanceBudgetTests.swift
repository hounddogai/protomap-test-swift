@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBudgetTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRemittanceBudget("code-957", title: "title-143")
        #expect(item.status == RevenueCycle.RemittanceBudgetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newRemittanceBudget("code-957", title: "title-143")
        try item.moveTo(RevenueCycle.RemittanceBudgetStatus.published)
        #expect(item.status == RevenueCycle.RemittanceBudgetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRemittanceBudget("code-957", title: "title-143")
        item.status = RevenueCycle.RemittanceBudgetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceBudgetStatus.created) }
    }
}
