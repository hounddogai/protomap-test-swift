@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMilestoneTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newFloatPoolMilestone("code-472", label: "label-44")
        #expect(item.status == Staffing.FloatPoolMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newFloatPoolMilestone("code-472", label: "label-44")
        try item.moveTo(Staffing.FloatPoolMilestoneStatus.suspended)
        #expect(item.status == Staffing.FloatPoolMilestoneStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newFloatPoolMilestone("code-472", label: "label-44")
        item.status = Staffing.FloatPoolMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolMilestoneStatus.draft) }
    }
}
