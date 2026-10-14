@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationManifestTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newLenientIsolationManifest("code-429", title: "title-469")
        #expect(item.status == BedManagement.LenientIsolationManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newLenientIsolationManifest("code-429", title: "title-469")
        try item.moveTo(BedManagement.LenientIsolationManifestStatus.inReview)
        #expect(item.status == BedManagement.LenientIsolationManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newLenientIsolationManifest("code-429", title: "title-469")
        item.status = BedManagement.LenientIsolationManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientIsolationManifestStatus.`open`) }
    }
}
