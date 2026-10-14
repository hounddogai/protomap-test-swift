@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePlanTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newOvertimePlan("code-138", title: "title-677")
        #expect(item.status == Staffing.OvertimePlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newOvertimePlan("code-138", title: "title-677")
        try item.moveTo(Staffing.OvertimePlanStatus.rejected)
        #expect(item.status == Staffing.OvertimePlanStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newOvertimePlan("code-138", title: "title-677")
        item.status = Staffing.OvertimePlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimePlanStatus.proposed) }
    }
}
