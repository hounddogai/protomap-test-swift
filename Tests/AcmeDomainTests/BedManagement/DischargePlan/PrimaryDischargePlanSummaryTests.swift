@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanSummaryTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newPrimaryDischargePlanSummary("code-379", title: "title-784")
        #expect(item.status == BedManagement.PrimaryDischargePlanSummaryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newPrimaryDischargePlanSummary("code-379", title: "title-784")
        try item.moveTo(BedManagement.PrimaryDischargePlanSummaryStatus.queued)
        #expect(item.status == BedManagement.PrimaryDischargePlanSummaryStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newPrimaryDischargePlanSummary("code-379", title: "title-784")
        item.status = BedManagement.PrimaryDischargePlanSummaryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryDischargePlanSummaryStatus.new) }
    }
}
