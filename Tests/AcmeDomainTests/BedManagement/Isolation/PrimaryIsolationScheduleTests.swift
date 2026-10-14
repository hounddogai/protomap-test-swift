@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationScheduleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newPrimaryIsolationSchedule("code-883", name: "name-770")
        #expect(item.status == BedManagement.PrimaryIsolationScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newPrimaryIsolationSchedule("code-883", name: "name-770")
        try item.moveTo(BedManagement.PrimaryIsolationScheduleStatus.inReview)
        #expect(item.status == BedManagement.PrimaryIsolationScheduleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newPrimaryIsolationSchedule("code-883", name: "name-770")
        item.status = BedManagement.PrimaryIsolationScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryIsolationScheduleStatus.`open`) }
    }
}
