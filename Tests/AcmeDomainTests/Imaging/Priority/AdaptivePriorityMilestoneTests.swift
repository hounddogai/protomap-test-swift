@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newAdaptivePriorityMilestone("code-169", name: "name-15")
        #expect(item.status == Imaging.AdaptivePriorityMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newAdaptivePriorityMilestone("code-169", name: "name-15")
        try item.moveTo(Imaging.AdaptivePriorityMilestoneStatus.granted)
        #expect(item.status == Imaging.AdaptivePriorityMilestoneStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newAdaptivePriorityMilestone("code-169", name: "name-15")
        item.status = Imaging.AdaptivePriorityMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptivePriorityMilestoneStatus.requested) }
    }
}
