@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistPlanTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newWorklistPlan("code-859", title: "title-905")
        #expect(item.status == Imaging.WorklistPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newWorklistPlan("code-859", title: "title-905")
        try item.moveTo(Imaging.WorklistPlanStatus.rejected)
        #expect(item.status == Imaging.WorklistPlanStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newWorklistPlan("code-859", title: "title-905")
        item.status = Imaging.WorklistPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistPlanStatus.proposed) }
    }
}
