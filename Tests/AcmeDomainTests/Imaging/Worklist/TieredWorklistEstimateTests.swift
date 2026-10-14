@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredWorklistEstimateTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newTieredWorklistEstimate("code-152", title: "title-277")
        #expect(item.status == Imaging.TieredWorklistEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newTieredWorklistEstimate("code-152", title: "title-277")
        try item.moveTo(Imaging.TieredWorklistEstimateStatus.published)
        #expect(item.status == Imaging.TieredWorklistEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newTieredWorklistEstimate("code-152", title: "title-277")
        item.status = Imaging.TieredWorklistEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredWorklistEstimateStatus.created) }
    }
}
