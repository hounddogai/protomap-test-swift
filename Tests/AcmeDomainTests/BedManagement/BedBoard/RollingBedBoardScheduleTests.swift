@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardScheduleTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newRollingBedBoardSchedule("code-41", label: "label-815")
        #expect(item.status == BedManagement.RollingBedBoardScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = BedManagement.newRollingBedBoardSchedule("code-41", label: "label-815")
        try item.moveTo(BedManagement.RollingBedBoardScheduleStatus.stopped)
        #expect(item.status == BedManagement.RollingBedBoardScheduleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newRollingBedBoardSchedule("code-41", label: "label-815")
        item.status = BedManagement.RollingBedBoardScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingBedBoardScheduleStatus.idle) }
    }
}
