@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanScheduleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newDischargePlanSchedule("code-864", title: "title-137")
        #expect(item.status == BedManagement.DischargePlanScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newDischargePlanSchedule("code-864", title: "title-137")
        try item.moveTo(BedManagement.DischargePlanScheduleStatus.resolved)
        #expect(item.status == BedManagement.DischargePlanScheduleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newDischargePlanSchedule("code-864", title: "title-137")
        item.status = BedManagement.DischargePlanScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanScheduleStatus.`open`) }
    }
}
