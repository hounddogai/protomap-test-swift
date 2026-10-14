@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimePlanTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newRegionalOvertimePlan("code-893", name: "name-61")
        #expect(item.status == Staffing.RegionalOvertimePlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newRegionalOvertimePlan("code-893", name: "name-61")
        try item.moveTo(Staffing.RegionalOvertimePlanStatus.rejected)
        #expect(item.status == Staffing.RegionalOvertimePlanStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newRegionalOvertimePlan("code-893", name: "name-61")
        item.status = Staffing.RegionalOvertimePlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalOvertimePlanStatus.proposed) }
    }
}
