@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledWorklistAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newScheduledWorklistAdjustment("code-706", label: "label-640")
        #expect(item.status == Imaging.ScheduledWorklistAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newScheduledWorklistAdjustment("code-706", label: "label-640")
        try item.moveTo(Imaging.ScheduledWorklistAdjustmentStatus.validated)
        #expect(item.status == Imaging.ScheduledWorklistAdjustmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newScheduledWorklistAdjustment("code-706", label: "label-640")
        item.status = Imaging.ScheduledWorklistAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledWorklistAdjustmentStatus.created) }
    }
}
