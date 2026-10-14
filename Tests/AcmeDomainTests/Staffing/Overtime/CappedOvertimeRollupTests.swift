@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedOvertimeRollupTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCappedOvertimeRollup("code-370", name: "name-341")
        #expect(item.status == Staffing.CappedOvertimeRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newCappedOvertimeRollup("code-370", name: "name-341")
        try item.moveTo(Staffing.CappedOvertimeRollupStatus.resolved)
        #expect(item.status == Staffing.CappedOvertimeRollupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCappedOvertimeRollup("code-370", name: "name-341")
        item.status = Staffing.CappedOvertimeRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedOvertimeRollupStatus.`open`) }
    }
}
