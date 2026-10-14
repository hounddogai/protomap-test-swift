@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedStudyPlanTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newWeightedStudyPlan("code-223", label: "label-576")
        #expect(item.status == Imaging.WeightedStudyPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newWeightedStudyPlan("code-223", label: "label-576")
        try item.moveTo(Imaging.WeightedStudyPlanStatus.reopened)
        #expect(item.status == Imaging.WeightedStudyPlanStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newWeightedStudyPlan("code-223", label: "label-576")
        item.status = Imaging.WeightedStudyPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedStudyPlanStatus.`open`) }
    }
}
