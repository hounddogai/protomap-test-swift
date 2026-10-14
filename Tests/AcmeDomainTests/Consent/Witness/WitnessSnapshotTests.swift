@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSnapshotTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessSnapshot("code-729", title: "title-825")
        #expect(item.status == Consent.WitnessSnapshotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newWitnessSnapshot("code-729", title: "title-825")
        try item.moveTo(Consent.WitnessSnapshotStatus.ready)
        #expect(item.status == Consent.WitnessSnapshotStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessSnapshot("code-729", title: "title-825")
        item.status = Consent.WitnessSnapshotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessSnapshotStatus.idle) }
    }
}
