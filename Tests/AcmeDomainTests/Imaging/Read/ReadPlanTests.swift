@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadPlanTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newReadPlan("code-582", title: "title-745")
        #expect(item.status == Imaging.ReadPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newReadPlan("code-582", title: "title-745")
        try item.moveTo(Imaging.ReadPlanStatus.stopped)
        #expect(item.status == Imaging.ReadPlanStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newReadPlan("code-582", title: "title-745")
        item.status = Imaging.ReadPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadPlanStatus.idle) }
    }
}
