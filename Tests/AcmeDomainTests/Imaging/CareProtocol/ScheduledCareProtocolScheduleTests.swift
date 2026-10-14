@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolScheduleTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newScheduledCareProtocolSchedule("code-270", name: "name-786")
        #expect(item.status == Imaging.ScheduledCareProtocolScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newScheduledCareProtocolSchedule("code-270", name: "name-786")
        try item.moveTo(Imaging.ScheduledCareProtocolScheduleStatus.warming)
        #expect(item.status == Imaging.ScheduledCareProtocolScheduleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newScheduledCareProtocolSchedule("code-270", name: "name-786")
        item.status = Imaging.ScheduledCareProtocolScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledCareProtocolScheduleStatus.idle) }
    }
}
