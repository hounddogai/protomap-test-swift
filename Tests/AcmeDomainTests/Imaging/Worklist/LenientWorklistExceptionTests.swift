@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientWorklistExceptionTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newLenientWorklistException("code-169", title: "title-249")
        #expect(item.status == Imaging.LenientWorklistExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newLenientWorklistException("code-169", title: "title-249")
        try item.moveTo(Imaging.LenientWorklistExceptionStatus.stopped)
        #expect(item.status == Imaging.LenientWorklistExceptionStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newLenientWorklistException("code-169", title: "title-249")
        item.status = Imaging.LenientWorklistExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientWorklistExceptionStatus.idle) }
    }
}
