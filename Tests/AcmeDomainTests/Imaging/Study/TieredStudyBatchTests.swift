@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudyBatchTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newTieredStudyBatch("code-623", name: "name-564")
        #expect(item.status == Imaging.TieredStudyBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newTieredStudyBatch("code-623", name: "name-564")
        try item.moveTo(Imaging.TieredStudyBatchStatus.cancelled)
        #expect(item.status == Imaging.TieredStudyBatchStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newTieredStudyBatch("code-623", name: "name-564")
        item.status = Imaging.TieredStudyBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredStudyBatchStatus.planned) }
    }
}
