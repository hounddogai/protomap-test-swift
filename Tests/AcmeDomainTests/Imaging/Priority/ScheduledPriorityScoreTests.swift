@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityScoreTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newScheduledPriorityScore("code-90", label: "label-405")
        #expect(item.status == Imaging.ScheduledPriorityScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newScheduledPriorityScore("code-90", label: "label-405")
        try item.moveTo(Imaging.ScheduledPriorityScoreStatus.validated)
        #expect(item.status == Imaging.ScheduledPriorityScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newScheduledPriorityScore("code-90", label: "label-405")
        item.status = Imaging.ScheduledPriorityScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledPriorityScoreStatus.created) }
    }
}
