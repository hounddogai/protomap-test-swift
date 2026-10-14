@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedModalityMappingTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newBatchedModalityMapping("code-226", name: "name-48")
        #expect(item.status == Imaging.BatchedModalityMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newBatchedModalityMapping("code-226", name: "name-48")
        try item.moveTo(Imaging.BatchedModalityMappingStatus.validated)
        #expect(item.status == Imaging.BatchedModalityMappingStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newBatchedModalityMapping("code-226", name: "name-48")
        item.status = Imaging.BatchedModalityMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedModalityMappingStatus.created) }
    }
}
