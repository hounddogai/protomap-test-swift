@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationManifestTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRollingRevocationManifest("code-919", name: "name-342")
        #expect(item.status == Consent.RollingRevocationManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRollingRevocationManifest("code-919", name: "name-342")
        try item.moveTo(Consent.RollingRevocationManifestStatus.validated)
        #expect(item.status == Consent.RollingRevocationManifestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRollingRevocationManifest("code-919", name: "name-342")
        item.status = Consent.RollingRevocationManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingRevocationManifestStatus.created) }
    }
}
