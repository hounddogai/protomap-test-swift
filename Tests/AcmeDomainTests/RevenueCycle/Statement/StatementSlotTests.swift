@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSlotTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStatementSlot("code-712", label: "label-958")
        #expect(item.status == RevenueCycle.StatementSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newStatementSlot("code-712", label: "label-958")
        try item.moveTo(RevenueCycle.StatementSlotStatus.published)
        #expect(item.status == RevenueCycle.StatementSlotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStatementSlot("code-712", label: "label-958")
        item.status = RevenueCycle.StatementSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementSlotStatus.created) }
    }
}
