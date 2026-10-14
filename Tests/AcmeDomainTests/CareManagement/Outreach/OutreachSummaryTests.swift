@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSummaryTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachSummary("code-703", title: "title-697")
        #expect(item.status == CareManagement.OutreachSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newOutreachSummary("code-703", title: "title-697")
        try item.moveTo(CareManagement.OutreachSummaryStatus.done)
        #expect(item.status == CareManagement.OutreachSummaryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachSummary("code-703", title: "title-697")
        item.status = CareManagement.OutreachSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachSummaryStatus.new) }
    }
}
