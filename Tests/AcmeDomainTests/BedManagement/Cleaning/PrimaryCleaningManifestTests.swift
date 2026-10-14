@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningManifestTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newPrimaryCleaningManifest("code-151", title: "title-56")
        #expect(item.status == BedManagement.PrimaryCleaningManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newPrimaryCleaningManifest("code-151", title: "title-56")
        try item.moveTo(BedManagement.PrimaryCleaningManifestStatus.reopened)
        #expect(item.status == BedManagement.PrimaryCleaningManifestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newPrimaryCleaningManifest("code-151", title: "title-56")
        item.status = BedManagement.PrimaryCleaningManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryCleaningManifestStatus.`open`) }
    }
}
