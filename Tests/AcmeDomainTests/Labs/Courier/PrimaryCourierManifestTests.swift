@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryCourierManifestTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPrimaryCourierManifest("code-512", title: "title-761")
        #expect(item.status == Labs.PrimaryCourierManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newPrimaryCourierManifest("code-512", title: "title-761")
        try item.moveTo(Labs.PrimaryCourierManifestStatus.scheduled)
        #expect(item.status == Labs.PrimaryCourierManifestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPrimaryCourierManifest("code-512", title: "title-761")
        item.status = Labs.PrimaryCourierManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryCourierManifestStatus.planned) }
    }
}
