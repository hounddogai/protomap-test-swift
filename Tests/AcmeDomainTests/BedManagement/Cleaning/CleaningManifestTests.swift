@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningManifestTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCleaningManifest("code-534", label: "label-607")
        #expect(item.status == BedManagement.CleaningManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newCleaningManifest("code-534", label: "label-607")
        try item.moveTo(BedManagement.CleaningManifestStatus.closed)
        #expect(item.status == BedManagement.CleaningManifestStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCleaningManifest("code-534", label: "label-607")
        item.status = BedManagement.CleaningManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningManifestStatus.draft) }
    }
}
