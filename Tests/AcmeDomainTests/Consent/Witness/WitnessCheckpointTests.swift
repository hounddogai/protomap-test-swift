@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessCheckpointTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessCheckpoint("code-552", title: "title-691")
        #expect(item.status == Consent.WitnessCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newWitnessCheckpoint("code-552", title: "title-691")
        try item.moveTo(Consent.WitnessCheckpointStatus.ready)
        #expect(item.status == Consent.WitnessCheckpointStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessCheckpoint("code-552", title: "title-691")
        item.status = Consent.WitnessCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessCheckpointStatus.idle) }
    }
}
