@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationManifestTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newFallbackIsolationManifest("code-664", name: "name-656")
        #expect(item.status == BedManagement.FallbackIsolationManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newFallbackIsolationManifest("code-664", name: "name-656")
        try item.moveTo(BedManagement.FallbackIsolationManifestStatus.published)
        #expect(item.status == BedManagement.FallbackIsolationManifestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newFallbackIsolationManifest("code-664", name: "name-656")
        item.status = BedManagement.FallbackIsolationManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackIsolationManifestStatus.created) }
    }
}
