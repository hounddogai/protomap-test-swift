@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistDigestTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newWorklistDigest("code-550", title: "title-82")
        #expect(item.status == Imaging.WorklistDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newWorklistDigest("code-550", title: "title-82")
        try item.moveTo(Imaging.WorklistDigestStatus.validated)
        #expect(item.status == Imaging.WorklistDigestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newWorklistDigest("code-550", title: "title-82")
        item.status = Imaging.WorklistDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistDigestStatus.created) }
    }
}
