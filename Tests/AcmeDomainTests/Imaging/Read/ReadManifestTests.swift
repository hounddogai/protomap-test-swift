@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadManifestTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newReadManifest("code-513", name: "name-474")
        #expect(item.status == Imaging.ReadManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newReadManifest("code-513", name: "name-474")
        try item.moveTo(Imaging.ReadManifestStatus.rejected)
        #expect(item.status == Imaging.ReadManifestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newReadManifest("code-513", name: "name-474")
        item.status = Imaging.ReadManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadManifestStatus.proposed) }
    }
}
