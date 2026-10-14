@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newSeasonalReadMilestone("code-966", name: "name-637")
        #expect(item.status == Imaging.SeasonalReadMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newSeasonalReadMilestone("code-966", name: "name-637")
        try item.moveTo(Imaging.SeasonalReadMilestoneStatus.granted)
        #expect(item.status == Imaging.SeasonalReadMilestoneStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newSeasonalReadMilestone("code-966", name: "name-637")
        item.status = Imaging.SeasonalReadMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalReadMilestoneStatus.requested) }
    }
}
