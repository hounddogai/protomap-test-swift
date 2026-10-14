@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadEstimateTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newManualReadEstimate("code-132", title: "title-721")
        #expect(item.status == Imaging.ManualReadEstimateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newManualReadEstimate("code-132", title: "title-721")
        try item.moveTo(Imaging.ManualReadEstimateStatus.published)
        #expect(item.status == Imaging.ManualReadEstimateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newManualReadEstimate("code-132", title: "title-721")
        item.status = Imaging.ManualReadEstimateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualReadEstimateStatus.created) }
    }
}
