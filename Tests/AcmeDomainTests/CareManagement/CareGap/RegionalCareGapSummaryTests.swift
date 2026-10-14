@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapSummaryTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRegionalCareGapSummary("code-667", label: "label-841")
        #expect(item.status == CareManagement.RegionalCareGapSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newRegionalCareGapSummary("code-667", label: "label-841")
        try item.moveTo(CareManagement.RegionalCareGapSummaryStatus.done)
        #expect(item.status == CareManagement.RegionalCareGapSummaryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRegionalCareGapSummary("code-667", label: "label-841")
        item.status = CareManagement.RegionalCareGapSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalCareGapSummaryStatus.new) }
    }
}
