@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyScheduleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newAdaptiveStudySchedule("code-283", name: "name-222")
        #expect(item.status == Imaging.AdaptiveStudyScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newAdaptiveStudySchedule("code-283", name: "name-222")
        try item.moveTo(Imaging.AdaptiveStudyScheduleStatus.running)
        #expect(item.status == Imaging.AdaptiveStudyScheduleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newAdaptiveStudySchedule("code-283", name: "name-222")
        item.status = Imaging.AdaptiveStudyScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveStudyScheduleStatus.new) }
    }
}
