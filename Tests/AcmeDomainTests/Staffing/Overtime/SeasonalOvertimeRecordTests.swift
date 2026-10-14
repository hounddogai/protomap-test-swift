@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalOvertimeRecordTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newSeasonalOvertimeRecord("code-708", label: "label-490")
        #expect(item.status == Staffing.SeasonalOvertimeRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newSeasonalOvertimeRecord("code-708", label: "label-490")
        try item.moveTo(Staffing.SeasonalOvertimeRecordStatus.inReview)
        #expect(item.status == Staffing.SeasonalOvertimeRecordStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newSeasonalOvertimeRecord("code-708", label: "label-490")
        item.status = Staffing.SeasonalOvertimeRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalOvertimeRecordStatus.`open`) }
    }
}
