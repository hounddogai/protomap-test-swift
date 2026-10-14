@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachRuleTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newTieredOutreachRule("code-127", name: "name-434")
        #expect(item.status == CareManagement.TieredOutreachRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newTieredOutreachRule("code-127", name: "name-434")
        try item.moveTo(CareManagement.TieredOutreachRuleStatus.completed)
        #expect(item.status == CareManagement.TieredOutreachRuleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newTieredOutreachRule("code-127", name: "name-434")
        item.status = CareManagement.TieredOutreachRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredOutreachRuleStatus.planned) }
    }
}
