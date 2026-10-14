@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedReadPlanTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newBatchedReadPlan("code-472", label: "label-930")
        #expect(item.status == Imaging.BatchedReadPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newBatchedReadPlan("code-472", label: "label-930")
        try item.moveTo(Imaging.BatchedReadPlanStatus.inProgress)
        #expect(item.status == Imaging.BatchedReadPlanStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newBatchedReadPlan("code-472", label: "label-930")
        item.status = Imaging.BatchedReadPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedReadPlanStatus.planned) }
    }
}
