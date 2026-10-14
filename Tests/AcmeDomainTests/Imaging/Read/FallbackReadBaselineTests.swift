@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackReadBaselineTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newFallbackReadBaseline("code-97", title: "title-654")
        #expect(item.status == Imaging.FallbackReadBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newFallbackReadBaseline("code-97", title: "title-654")
        try item.moveTo(Imaging.FallbackReadBaselineStatus.ready)
        #expect(item.status == Imaging.FallbackReadBaselineStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newFallbackReadBaseline("code-97", title: "title-654")
        item.status = Imaging.FallbackReadBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackReadBaselineStatus.idle) }
    }
}
