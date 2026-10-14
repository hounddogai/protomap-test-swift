@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityMappingTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newManualModalityMapping("code-580", title: "title-882")
        #expect(item.status == Imaging.ManualModalityMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newManualModalityMapping("code-580", title: "title-882")
        try item.moveTo(Imaging.ManualModalityMappingStatus.inProgress)
        #expect(item.status == Imaging.ManualModalityMappingStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newManualModalityMapping("code-580", title: "title-882")
        item.status = Imaging.ManualModalityMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualModalityMappingStatus.planned) }
    }
}
