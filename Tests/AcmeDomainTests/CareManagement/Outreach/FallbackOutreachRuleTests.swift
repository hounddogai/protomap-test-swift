@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachRuleTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newFallbackOutreachRule("code-971", label: "label-270")
        #expect(item.status == CareManagement.FallbackOutreachRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newFallbackOutreachRule("code-971", label: "label-270")
        try item.moveTo(CareManagement.FallbackOutreachRuleStatus.inProgress)
        #expect(item.status == CareManagement.FallbackOutreachRuleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newFallbackOutreachRule("code-971", label: "label-270")
        item.status = CareManagement.FallbackOutreachRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackOutreachRuleStatus.planned) }
    }
}
