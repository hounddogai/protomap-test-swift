@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityPlanTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newManualModalityPlan("code-87", title: "title-893")
        #expect(item.status == Imaging.ManualModalityPlanStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newManualModalityPlan("code-87", title: "title-893")
        try item.moveTo(Imaging.ManualModalityPlanStatus.inReview)
        #expect(item.status == Imaging.ManualModalityPlanStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newManualModalityPlan("code-87", title: "title-893")
        item.status = Imaging.ManualModalityPlanStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualModalityPlanStatus.`open`) }
    }
}
