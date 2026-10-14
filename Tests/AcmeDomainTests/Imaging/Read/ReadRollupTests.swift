@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRollupTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newReadRollup("code-15", title: "title-196")
        #expect(item.status == Imaging.ReadRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newReadRollup("code-15", title: "title-196")
        try item.moveTo(Imaging.ReadRollupStatus.granted)
        #expect(item.status == Imaging.ReadRollupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newReadRollup("code-15", title: "title-196")
        item.status = Imaging.ReadRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadRollupStatus.requested) }
    }
}
