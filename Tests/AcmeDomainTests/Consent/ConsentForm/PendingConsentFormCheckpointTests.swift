@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingConsentFormCheckpointTests {
    @Test func startsInIdle() throws {
        let item = Consent.newPendingConsentFormCheckpoint("code-238", name: "name-711")
        #expect(item.status == Consent.PendingConsentFormCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newPendingConsentFormCheckpoint("code-238", name: "name-711")
        try item.moveTo(Consent.PendingConsentFormCheckpointStatus.warming)
        #expect(item.status == Consent.PendingConsentFormCheckpointStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newPendingConsentFormCheckpoint("code-238", name: "name-711")
        item.status = Consent.PendingConsentFormCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingConsentFormCheckpointStatus.idle) }
    }
}
