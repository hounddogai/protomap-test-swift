@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSummaryTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newLegacyGoalSummary("code-168", title: "title-985")
        #expect(item.status == CareManagement.LegacyGoalSummaryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newLegacyGoalSummary("code-168", title: "title-985")
        try item.moveTo(CareManagement.LegacyGoalSummaryStatus.inReview)
        #expect(item.status == CareManagement.LegacyGoalSummaryStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newLegacyGoalSummary("code-168", title: "title-985")
        item.status = CareManagement.LegacyGoalSummaryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyGoalSummaryStatus.`open`) }
    }
}
