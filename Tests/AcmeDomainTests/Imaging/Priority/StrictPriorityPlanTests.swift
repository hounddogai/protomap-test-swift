@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityPlanTests {
    @Test func startsInNew() throws {
        let item = Imaging.newStrictPriorityPlan("code-170", title: "title-256")
        #expect(item.status == Imaging.StrictPriorityPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newStrictPriorityPlan("code-170", title: "title-256")
        try item.moveTo(Imaging.StrictPriorityPlanStatus.done)
        #expect(item.status == Imaging.StrictPriorityPlanStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newStrictPriorityPlan("code-170", title: "title-256")
        item.status = Imaging.StrictPriorityPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictPriorityPlanStatus.new) }
    }
}
