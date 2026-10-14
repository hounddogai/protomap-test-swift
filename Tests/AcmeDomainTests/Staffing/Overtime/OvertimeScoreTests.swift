@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeScoreTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newOvertimeScore("code-109", title: "title-685")
        #expect(item.status == Staffing.OvertimeScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newOvertimeScore("code-109", title: "title-685")
        try item.moveTo(Staffing.OvertimeScoreStatus.resolved)
        #expect(item.status == Staffing.OvertimeScoreStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newOvertimeScore("code-109", title: "title-685")
        item.status = Staffing.OvertimeScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeScoreStatus.`open`) }
    }
}
