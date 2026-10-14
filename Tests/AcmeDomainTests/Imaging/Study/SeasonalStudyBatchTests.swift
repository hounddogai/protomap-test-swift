@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyBatchTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newSeasonalStudyBatch("code-22", name: "name-86")
        #expect(item.status == Imaging.SeasonalStudyBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newSeasonalStudyBatch("code-22", name: "name-86")
        try item.moveTo(Imaging.SeasonalStudyBatchStatus.withdrawn)
        #expect(item.status == Imaging.SeasonalStudyBatchStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newSeasonalStudyBatch("code-22", name: "name-86")
        item.status = Imaging.SeasonalStudyBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalStudyBatchStatus.proposed) }
    }
}
