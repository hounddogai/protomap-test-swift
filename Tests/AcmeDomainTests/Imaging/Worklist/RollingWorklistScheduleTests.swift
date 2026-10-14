@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingWorklistScheduleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newRollingWorklistSchedule("code-487", label: "label-743")
        #expect(item.status == Imaging.RollingWorklistScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newRollingWorklistSchedule("code-487", label: "label-743")
        try item.moveTo(Imaging.RollingWorklistScheduleStatus.published)
        #expect(item.status == Imaging.RollingWorklistScheduleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newRollingWorklistSchedule("code-487", label: "label-743")
        item.status = Imaging.RollingWorklistScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingWorklistScheduleStatus.created) }
    }
}
