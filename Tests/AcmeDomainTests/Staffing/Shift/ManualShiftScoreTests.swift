@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftScoreTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newManualShiftScore("code-240", name: "name-120")
        #expect(item.status == Staffing.ManualShiftScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newManualShiftScore("code-240", name: "name-120")
        try item.moveTo(Staffing.ManualShiftScoreStatus.resolved)
        #expect(item.status == Staffing.ManualShiftScoreStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newManualShiftScore("code-240", name: "name-120")
        item.status = Staffing.ManualShiftScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualShiftScoreStatus.`open`) }
    }
}
