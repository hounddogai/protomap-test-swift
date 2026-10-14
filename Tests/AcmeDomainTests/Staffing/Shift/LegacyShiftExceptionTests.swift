@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftExceptionTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newLegacyShiftException("code-464", name: "name-417")
        #expect(item.status == Staffing.LegacyShiftExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newLegacyShiftException("code-464", name: "name-417")
        try item.moveTo(Staffing.LegacyShiftExceptionStatus.reopened)
        #expect(item.status == Staffing.LegacyShiftExceptionStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newLegacyShiftException("code-464", name: "name-417")
        item.status = Staffing.LegacyShiftExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyShiftExceptionStatus.`open`) }
    }
}
