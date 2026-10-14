@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadPlanTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newSeasonalReadPlan("code-396", name: "name-111")
        #expect(item.status == Imaging.SeasonalReadPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Imaging.newSeasonalReadPlan("code-396", name: "name-111")
        try item.moveTo(Imaging.SeasonalReadPlanStatus.active)
        #expect(item.status == Imaging.SeasonalReadPlanStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newSeasonalReadPlan("code-396", name: "name-111")
        item.status = Imaging.SeasonalReadPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalReadPlanStatus.draft) }
    }
}
