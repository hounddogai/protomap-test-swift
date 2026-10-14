@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBatchTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newWorklistBatch("code-614", label: "label-489")
        #expect(item.status == Imaging.WorklistBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newWorklistBatch("code-614", label: "label-489")
        try item.moveTo(Imaging.WorklistBatchStatus.rejected)
        #expect(item.status == Imaging.WorklistBatchStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newWorklistBatch("code-614", label: "label-489")
        item.status = Imaging.WorklistBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistBatchStatus.proposed) }
    }
}
