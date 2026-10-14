@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBatchTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPriorityBatch("code-87", label: "label-118")
        #expect(item.status == Imaging.PriorityBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newPriorityBatch("code-87", label: "label-118")
        try item.moveTo(Imaging.PriorityBatchStatus.validated)
        #expect(item.status == Imaging.PriorityBatchStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPriorityBatch("code-87", label: "label-118")
        item.status = Imaging.PriorityBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityBatchStatus.created) }
    }
}
