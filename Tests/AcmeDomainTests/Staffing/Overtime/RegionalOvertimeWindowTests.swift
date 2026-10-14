@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeWindowTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newRegionalOvertimeWindow("code-386", name: "name-539")
        #expect(item.status == Staffing.RegionalOvertimeWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newRegionalOvertimeWindow("code-386", name: "name-539")
        try item.moveTo(Staffing.RegionalOvertimeWindowStatus.inProgress)
        #expect(item.status == Staffing.RegionalOvertimeWindowStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newRegionalOvertimeWindow("code-386", name: "name-539")
        item.status = Staffing.RegionalOvertimeWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalOvertimeWindowStatus.planned) }
    }
}
