@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyManifestTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRegionalProxyManifest("code-2", label: "label-791")
        #expect(item.status == Consent.RegionalProxyManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newRegionalProxyManifest("code-2", label: "label-791")
        try item.moveTo(Consent.RegionalProxyManifestStatus.retired)
        #expect(item.status == Consent.RegionalProxyManifestStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRegionalProxyManifest("code-2", label: "label-791")
        item.status = Consent.RegionalProxyManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalProxyManifestStatus.created) }
    }
}
