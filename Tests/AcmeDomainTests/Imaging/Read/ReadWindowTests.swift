@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadWindowTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newReadWindow("code-975", label: "label-625")
        #expect(item.status == Imaging.ReadWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newReadWindow("code-975", label: "label-625")
        try item.moveTo(Imaging.ReadWindowStatus.granted)
        #expect(item.status == Imaging.ReadWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newReadWindow("code-975", label: "label-625")
        item.status = Imaging.ReadWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadWindowStatus.requested) }
    }
}
