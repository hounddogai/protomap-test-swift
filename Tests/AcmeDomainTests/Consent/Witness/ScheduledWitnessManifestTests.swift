@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessManifestTests {
    @Test func startsInNew() throws {
        let item = Consent.newScheduledWitnessManifest("code-991", name: "name-447")
        #expect(item.status == Consent.ScheduledWitnessManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newScheduledWitnessManifest("code-991", name: "name-447")
        try item.moveTo(Consent.ScheduledWitnessManifestStatus.done)
        #expect(item.status == Consent.ScheduledWitnessManifestStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newScheduledWitnessManifest("code-991", name: "name-447")
        item.status = Consent.ScheduledWitnessManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledWitnessManifestStatus.new) }
    }
}
