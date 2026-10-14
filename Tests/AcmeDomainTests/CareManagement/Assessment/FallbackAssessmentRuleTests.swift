@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentRuleTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newFallbackAssessmentRule("code-192", name: "name-801")
        #expect(item.status == CareManagement.FallbackAssessmentRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newFallbackAssessmentRule("code-192", name: "name-801")
        try item.moveTo(CareManagement.FallbackAssessmentRuleStatus.queued)
        #expect(item.status == CareManagement.FallbackAssessmentRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newFallbackAssessmentRule("code-192", name: "name-801")
        item.status = CareManagement.FallbackAssessmentRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackAssessmentRuleStatus.new) }
    }
}
