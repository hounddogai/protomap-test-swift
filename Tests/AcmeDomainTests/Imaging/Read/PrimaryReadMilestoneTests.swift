@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPrimaryReadMilestone("code-526", title: "title-648")
        #expect(item.status == Imaging.PrimaryReadMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newPrimaryReadMilestone("code-526", title: "title-648")
        try item.moveTo(Imaging.PrimaryReadMilestoneStatus.scheduled)
        #expect(item.status == Imaging.PrimaryReadMilestoneStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPrimaryReadMilestone("code-526", title: "title-648")
        item.status = Imaging.PrimaryReadMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryReadMilestoneStatus.planned) }
    }
}
