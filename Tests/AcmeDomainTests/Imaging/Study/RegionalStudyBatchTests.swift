@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyBatchTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newRegionalStudyBatch("code-908", label: "label-636")
        #expect(item.status == Imaging.RegionalStudyBatchStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newRegionalStudyBatch("code-908", label: "label-636")
        try item.moveTo(Imaging.RegionalStudyBatchStatus.withdrawn)
        #expect(item.status == Imaging.RegionalStudyBatchStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newRegionalStudyBatch("code-908", label: "label-636")
        item.status = Imaging.RegionalStudyBatchStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalStudyBatchStatus.proposed) }
    }
}
