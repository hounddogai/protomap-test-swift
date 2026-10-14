@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadExceptionTests {
    @Test func startsInNew() throws {
        let item = Imaging.newReadException("code-536", label: "label-559")
        #expect(item.status == Imaging.ReadExceptionStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newReadException("code-536", label: "label-559")
        try item.moveTo(Imaging.ReadExceptionStatus.queued)
        #expect(item.status == Imaging.ReadExceptionStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newReadException("code-536", label: "label-559")
        item.status = Imaging.ReadExceptionStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadExceptionStatus.new) }
    }
}
