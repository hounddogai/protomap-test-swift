@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultModalityMappingTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newDefaultModalityMapping("code-10", title: "title-677")
        #expect(item.status == Imaging.DefaultModalityMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newDefaultModalityMapping("code-10", title: "title-677")
        try item.moveTo(Imaging.DefaultModalityMappingStatus.draining)
        #expect(item.status == Imaging.DefaultModalityMappingStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newDefaultModalityMapping("code-10", title: "title-677")
        item.status = Imaging.DefaultModalityMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultModalityMappingStatus.idle) }
    }
}
