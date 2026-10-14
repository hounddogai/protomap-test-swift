@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientRevocationManifestTests {
    @Test func startsInDraft() throws {
        let item = Consent.newLenientRevocationManifest("code-496", label: "label-614")
        #expect(item.status == Consent.LenientRevocationManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newLenientRevocationManifest("code-496", label: "label-614")
        try item.moveTo(Consent.LenientRevocationManifestStatus.pending)
        #expect(item.status == Consent.LenientRevocationManifestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newLenientRevocationManifest("code-496", label: "label-614")
        item.status = Consent.LenientRevocationManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientRevocationManifestStatus.draft) }
    }
}
