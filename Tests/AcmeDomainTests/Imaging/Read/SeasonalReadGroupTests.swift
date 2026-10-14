@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadGroupTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newSeasonalReadGroup("code-147", label: "label-143")
        #expect(item.status == Imaging.SeasonalReadGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newSeasonalReadGroup("code-147", label: "label-143")
        try item.moveTo(Imaging.SeasonalReadGroupStatus.approved)
        #expect(item.status == Imaging.SeasonalReadGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newSeasonalReadGroup("code-147", label: "label-143")
        item.status = Imaging.SeasonalReadGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalReadGroupStatus.proposed) }
    }
}
