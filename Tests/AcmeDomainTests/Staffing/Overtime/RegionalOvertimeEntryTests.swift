@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeEntryTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newRegionalOvertimeEntry("code-850", name: "name-607")
        #expect(item.status == Staffing.RegionalOvertimeEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newRegionalOvertimeEntry("code-850", name: "name-607")
        try item.moveTo(Staffing.RegionalOvertimeEntryStatus.scheduled)
        #expect(item.status == Staffing.RegionalOvertimeEntryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newRegionalOvertimeEntry("code-850", name: "name-607")
        item.status = Staffing.RegionalOvertimeEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalOvertimeEntryStatus.planned) }
    }
}
