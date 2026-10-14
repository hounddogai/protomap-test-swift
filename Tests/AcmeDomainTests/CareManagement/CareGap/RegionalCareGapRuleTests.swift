@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapRuleTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRegionalCareGapRule("code-741", title: "title-654")
        #expect(item.status == CareManagement.RegionalCareGapRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRegionalCareGapRule("code-741", title: "title-654")
        try item.moveTo(CareManagement.RegionalCareGapRuleStatus.pending)
        #expect(item.status == CareManagement.RegionalCareGapRuleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRegionalCareGapRule("code-741", title: "title-654")
        item.status = CareManagement.RegionalCareGapRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalCareGapRuleStatus.draft) }
    }
}
