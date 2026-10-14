@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPreferenceTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStatementPreference("code-482", name: "name-888")
        #expect(item.status == RevenueCycle.StatementPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newStatementPreference("code-482", name: "name-888")
        try item.moveTo(RevenueCycle.StatementPreferenceStatus.published)
        #expect(item.status == RevenueCycle.StatementPreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStatementPreference("code-482", name: "name-888")
        item.status = RevenueCycle.StatementPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementPreferenceStatus.created) }
    }
}
