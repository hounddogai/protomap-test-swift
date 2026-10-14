@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistRequestTests {
    @Test func startsInNew() throws {
        let item = Imaging.newFallbackWorklistRequest("code-978", label: "label-296")
        #expect(item.status == Imaging.FallbackWorklistRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newFallbackWorklistRequest("code-978", label: "label-296")
        try item.moveTo(Imaging.FallbackWorklistRequestStatus.running)
        #expect(item.status == Imaging.FallbackWorklistRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newFallbackWorklistRequest("code-978", label: "label-296")
        item.status = Imaging.FallbackWorklistRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackWorklistRequestStatus.new) }
    }
}
