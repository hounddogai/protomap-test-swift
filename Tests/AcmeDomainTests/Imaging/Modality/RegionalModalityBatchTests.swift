@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalModalityBatchTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newRegionalModalityBatch("code-925", label: "label-150")
        #expect(item.status == Imaging.RegionalModalityBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newRegionalModalityBatch("code-925", label: "label-150")
        try item.moveTo(Imaging.RegionalModalityBatchStatus.inReview)
        #expect(item.status == Imaging.RegionalModalityBatchStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newRegionalModalityBatch("code-925", label: "label-150")
        item.status = Imaging.RegionalModalityBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalModalityBatchStatus.`open`) }
    }
}
