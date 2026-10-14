@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationManifestTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newIsolationManifest("code-541", label: "label-629")
        #expect(item.status == BedManagement.IsolationManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newIsolationManifest("code-541", label: "label-629")
        try item.moveTo(BedManagement.IsolationManifestStatus.resolved)
        #expect(item.status == BedManagement.IsolationManifestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newIsolationManifest("code-541", label: "label-629")
        item.status = BedManagement.IsolationManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationManifestStatus.`open`) }
    }
}
