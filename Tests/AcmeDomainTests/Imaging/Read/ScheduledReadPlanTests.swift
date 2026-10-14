@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledReadPlanTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newScheduledReadPlan("code-259", title: "title-372")
        #expect(item.status == Imaging.ScheduledReadPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newScheduledReadPlan("code-259", title: "title-372")
        try item.moveTo(Imaging.ScheduledReadPlanStatus.granted)
        #expect(item.status == Imaging.ScheduledReadPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newScheduledReadPlan("code-259", title: "title-372")
        item.status = Imaging.ScheduledReadPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledReadPlanStatus.requested) }
    }
}
