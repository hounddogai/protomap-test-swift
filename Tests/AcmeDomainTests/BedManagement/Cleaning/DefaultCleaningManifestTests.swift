@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningManifestTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDefaultCleaningManifest("code-736", label: "label-953")
        #expect(item.status == BedManagement.DefaultCleaningManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newDefaultCleaningManifest("code-736", label: "label-953")
        try item.moveTo(BedManagement.DefaultCleaningManifestStatus.granted)
        #expect(item.status == BedManagement.DefaultCleaningManifestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDefaultCleaningManifest("code-736", label: "label-953")
        item.status = BedManagement.DefaultCleaningManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultCleaningManifestStatus.requested) }
    }
}
