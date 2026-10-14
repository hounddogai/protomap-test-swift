@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistPlanTests {
    @Test func startsInNew() throws {
        let item = Imaging.newStrictWorklistPlan("code-74", title: "title-960")
        #expect(item.status == Imaging.StrictWorklistPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newStrictWorklistPlan("code-74", title: "title-960")
        try item.moveTo(Imaging.StrictWorklistPlanStatus.queued)
        #expect(item.status == Imaging.StrictWorklistPlanStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newStrictWorklistPlan("code-74", title: "title-960")
        item.status = Imaging.StrictWorklistPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictWorklistPlanStatus.new) }
    }
}
