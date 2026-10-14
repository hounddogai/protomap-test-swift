@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessManifestTests {
    @Test func startsInNew() throws {
        let item = Consent.newWitnessManifest("code-102", title: "title-464")
        #expect(item.status == Consent.WitnessManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newWitnessManifest("code-102", title: "title-464")
        try item.moveTo(Consent.WitnessManifestStatus.running)
        #expect(item.status == Consent.WitnessManifestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newWitnessManifest("code-102", title: "title-464")
        item.status = Consent.WitnessManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessManifestStatus.new) }
    }
}
