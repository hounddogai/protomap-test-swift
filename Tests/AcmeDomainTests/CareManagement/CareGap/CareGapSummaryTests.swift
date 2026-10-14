@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapSummaryTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newCareGapSummary("code-60", title: "title-324")
        #expect(item.status == CareManagement.CareGapSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newCareGapSummary("code-60", title: "title-324")
        try item.moveTo(CareManagement.CareGapSummaryStatus.ready)
        #expect(item.status == CareManagement.CareGapSummaryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newCareGapSummary("code-60", title: "title-324")
        item.status = CareManagement.CareGapSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapSummaryStatus.idle) }
    }
}
