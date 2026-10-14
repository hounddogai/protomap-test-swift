@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardScheduleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBedBoardSchedule("code-49", name: "name-589")
        #expect(item.status == BedManagement.BedBoardScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newBedBoardSchedule("code-49", name: "name-589")
        try item.moveTo(BedManagement.BedBoardScheduleStatus.inReview)
        #expect(item.status == BedManagement.BedBoardScheduleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBedBoardSchedule("code-49", name: "name-589")
        item.status = BedManagement.BedBoardScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardScheduleStatus.`open`) }
    }
}
