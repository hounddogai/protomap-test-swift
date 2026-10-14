@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedWorklistTemplateTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newWeightedWorklistTemplate("code-466", title: "title-357")
        #expect(item.status == Imaging.WeightedWorklistTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newWeightedWorklistTemplate("code-466", title: "title-357")
        try item.moveTo(Imaging.WeightedWorklistTemplateStatus.warming)
        #expect(item.status == Imaging.WeightedWorklistTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newWeightedWorklistTemplate("code-466", title: "title-357")
        item.status = Imaging.WeightedWorklistTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedWorklistTemplateStatus.idle) }
    }
}
