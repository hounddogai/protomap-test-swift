@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSummaryTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newDischargePlanSummary("code-768", label: "label-659")
        #expect(item.status == BedManagement.DischargePlanSummaryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newDischargePlanSummary("code-768", label: "label-659")
        try item.moveTo(BedManagement.DischargePlanSummaryStatus.approved)
        #expect(item.status == BedManagement.DischargePlanSummaryStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newDischargePlanSummary("code-768", label: "label-659")
        item.status = BedManagement.DischargePlanSummaryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanSummaryStatus.proposed) }
    }
}
