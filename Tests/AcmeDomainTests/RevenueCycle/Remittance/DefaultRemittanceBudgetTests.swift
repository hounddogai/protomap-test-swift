@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceBudgetTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newDefaultRemittanceBudget("code-756", title: "title-169")
        #expect(item.status == RevenueCycle.DefaultRemittanceBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newDefaultRemittanceBudget("code-756", title: "title-169")
        try item.moveTo(RevenueCycle.DefaultRemittanceBudgetStatus.granted)
        #expect(item.status == RevenueCycle.DefaultRemittanceBudgetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newDefaultRemittanceBudget("code-756", title: "title-169")
        item.status = RevenueCycle.DefaultRemittanceBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultRemittanceBudgetStatus.requested) }
    }
}
