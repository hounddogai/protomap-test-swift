@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityMappingTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newSeasonalPriorityMapping("code-344", name: "name-605")
        #expect(item.status == Imaging.SeasonalPriorityMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newSeasonalPriorityMapping("code-344", name: "name-605")
        try item.moveTo(Imaging.SeasonalPriorityMappingStatus.completed)
        #expect(item.status == Imaging.SeasonalPriorityMappingStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newSeasonalPriorityMapping("code-344", name: "name-605")
        item.status = Imaging.SeasonalPriorityMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalPriorityMappingStatus.planned) }
    }
}
