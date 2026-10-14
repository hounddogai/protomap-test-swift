@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityGroupTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newFallbackModalityGroup("code-423", title: "title-279")
        #expect(item.status == Imaging.FallbackModalityGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newFallbackModalityGroup("code-423", title: "title-279")
        try item.moveTo(Imaging.FallbackModalityGroupStatus.ready)
        #expect(item.status == Imaging.FallbackModalityGroupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newFallbackModalityGroup("code-423", title: "title-279")
        item.status = Imaging.FallbackModalityGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackModalityGroupStatus.idle) }
    }
}
