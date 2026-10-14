@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyManifestTests {
    @Test func startsInDraft() throws {
        let item = Consent.newStrictProxyManifest("code-756", label: "label-179")
        #expect(item.status == Consent.StrictProxyManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newStrictProxyManifest("code-756", label: "label-179")
        try item.moveTo(Consent.StrictProxyManifestStatus.active)
        #expect(item.status == Consent.StrictProxyManifestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newStrictProxyManifest("code-756", label: "label-179")
        item.status = Consent.StrictProxyManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictProxyManifestStatus.draft) }
    }
}
