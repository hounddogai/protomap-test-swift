@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSnapshotTests {
    @Test func startsInNew() throws {
        let item = Consent.newDisclosureSnapshot("code-940", title: "title-514")
        #expect(item.status == Consent.DisclosureSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newDisclosureSnapshot("code-940", title: "title-514")
        try item.moveTo(Consent.DisclosureSnapshotStatus.running)
        #expect(item.status == Consent.DisclosureSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newDisclosureSnapshot("code-940", title: "title-514")
        item.status = Consent.DisclosureSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureSnapshotStatus.new) }
    }
}
