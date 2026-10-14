@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityMappingTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCappedModalityMapping("code-833", title: "title-413")
        #expect(item.status == Imaging.CappedModalityMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newCappedModalityMapping("code-833", title: "title-413")
        try item.moveTo(Imaging.CappedModalityMappingStatus.granted)
        #expect(item.status == Imaging.CappedModalityMappingStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCappedModalityMapping("code-833", title: "title-413")
        item.status = Imaging.CappedModalityMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityMappingStatus.requested) }
    }
}
