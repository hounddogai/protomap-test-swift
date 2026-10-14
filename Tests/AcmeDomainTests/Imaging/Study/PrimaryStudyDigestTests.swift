@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyDigestTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPrimaryStudyDigest("code-420", name: "name-961")
        #expect(item.status == Imaging.PrimaryStudyDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newPrimaryStudyDigest("code-420", name: "name-961")
        try item.moveTo(Imaging.PrimaryStudyDigestStatus.rejected)
        #expect(item.status == Imaging.PrimaryStudyDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPrimaryStudyDigest("code-420", name: "name-961")
        item.status = Imaging.PrimaryStudyDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryStudyDigestStatus.proposed) }
    }
}
