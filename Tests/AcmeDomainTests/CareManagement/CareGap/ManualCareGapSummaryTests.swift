@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapSummaryTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newManualCareGapSummary("code-294", name: "name-418")
        #expect(item.status == CareManagement.ManualCareGapSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newManualCareGapSummary("code-294", name: "name-418")
        try item.moveTo(CareManagement.ManualCareGapSummaryStatus.validated)
        #expect(item.status == CareManagement.ManualCareGapSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newManualCareGapSummary("code-294", name: "name-418")
        item.status = CareManagement.ManualCareGapSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualCareGapSummaryStatus.created) }
    }
}
