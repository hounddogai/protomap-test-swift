@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadPlanTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newManualReadPlan("code-524", name: "name-775")
        #expect(item.status == Imaging.ManualReadPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newManualReadPlan("code-524", name: "name-775")
        try item.moveTo(Imaging.ManualReadPlanStatus.published)
        #expect(item.status == Imaging.ManualReadPlanStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newManualReadPlan("code-524", name: "name-775")
        item.status = Imaging.ManualReadPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualReadPlanStatus.created) }
    }
}
