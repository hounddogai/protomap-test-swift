@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapRuleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapRule("code-123", name: "name-904")
        #expect(item.status == CareManagement.CareGapRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newCareGapRule("code-123", name: "name-904")
        try item.moveTo(CareManagement.CareGapRuleStatus.inReview)
        #expect(item.status == CareManagement.CareGapRuleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapRule("code-123", name: "name-904")
        item.status = CareManagement.CareGapRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapRuleStatus.`open`) }
    }
}
