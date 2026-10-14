@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalRiskScoreSummaryTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRegionalRiskScoreSummary("code-17", title: "title-540")
        #expect(item.status == CareManagement.RegionalRiskScoreSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newRegionalRiskScoreSummary("code-17", title: "title-540")
        try item.moveTo(CareManagement.RegionalRiskScoreSummaryStatus.published)
        #expect(item.status == CareManagement.RegionalRiskScoreSummaryStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRegionalRiskScoreSummary("code-17", title: "title-540")
        item.status = CareManagement.RegionalRiskScoreSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalRiskScoreSummaryStatus.created) }
    }
}
