@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newAdaptiveConsentFormCheckpoint("code-911", title: "title-408")
        #expect(item.status == Consent.AdaptiveConsentFormCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newAdaptiveConsentFormCheckpoint("code-911", title: "title-408")
        try item.moveTo(Consent.AdaptiveConsentFormCheckpointStatus.inProgress)
        #expect(item.status == Consent.AdaptiveConsentFormCheckpointStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newAdaptiveConsentFormCheckpoint("code-911", title: "title-408")
        item.status = Consent.AdaptiveConsentFormCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveConsentFormCheckpointStatus.planned) }
    }
}
