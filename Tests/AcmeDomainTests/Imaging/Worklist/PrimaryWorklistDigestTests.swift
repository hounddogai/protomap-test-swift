@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistDigestTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPrimaryWorklistDigest("code-811", title: "title-289")
        #expect(item.status == Imaging.PrimaryWorklistDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newPrimaryWorklistDigest("code-811", title: "title-289")
        try item.moveTo(Imaging.PrimaryWorklistDigestStatus.scheduled)
        #expect(item.status == Imaging.PrimaryWorklistDigestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPrimaryWorklistDigest("code-811", title: "title-289")
        item.status = Imaging.PrimaryWorklistDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryWorklistDigestStatus.planned) }
    }
}
