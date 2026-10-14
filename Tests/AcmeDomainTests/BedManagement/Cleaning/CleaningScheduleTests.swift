@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningScheduleTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCleaningSchedule("code-144", name: "name-482")
        #expect(item.status == BedManagement.CleaningScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newCleaningSchedule("code-144", name: "name-482")
        try item.moveTo(BedManagement.CleaningScheduleStatus.approved)
        #expect(item.status == BedManagement.CleaningScheduleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCleaningSchedule("code-144", name: "name-482")
        item.status = BedManagement.CleaningScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningScheduleStatus.proposed) }
    }
}
