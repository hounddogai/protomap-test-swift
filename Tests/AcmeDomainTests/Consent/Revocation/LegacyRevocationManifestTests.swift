@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyRevocationManifestTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLegacyRevocationManifest("code-35", name: "name-3")
        #expect(item.status == Consent.LegacyRevocationManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newLegacyRevocationManifest("code-35", name: "name-3")
        try item.moveTo(Consent.LegacyRevocationManifestStatus.granted)
        #expect(item.status == Consent.LegacyRevocationManifestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLegacyRevocationManifest("code-35", name: "name-3")
        item.status = Consent.LegacyRevocationManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyRevocationManifestStatus.requested) }
    }
}
