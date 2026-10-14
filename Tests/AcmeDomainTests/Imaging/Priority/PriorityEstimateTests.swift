@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityEstimateTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newPriorityEstimate("code-841", label: "label-53")
        #expect(item.status == Imaging.PriorityEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newPriorityEstimate("code-841", label: "label-53")
        try item.moveTo(Imaging.PriorityEstimateStatus.pending)
        #expect(item.status == Imaging.PriorityEstimateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newPriorityEstimate("code-841", label: "label-53")
        item.status = Imaging.PriorityEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityEstimateStatus.draft) }
    }
}
