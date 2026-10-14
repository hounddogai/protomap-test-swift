@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistScheduleTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newWorklistSchedule("code-682", title: "title-53")
        #expect(item.status == Imaging.WorklistScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newWorklistSchedule("code-682", title: "title-53")
        try item.moveTo(Imaging.WorklistScheduleStatus.revoked)
        #expect(item.status == Imaging.WorklistScheduleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newWorklistSchedule("code-682", title: "title-53")
        item.status = Imaging.WorklistScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistScheduleStatus.requested) }
    }
}
