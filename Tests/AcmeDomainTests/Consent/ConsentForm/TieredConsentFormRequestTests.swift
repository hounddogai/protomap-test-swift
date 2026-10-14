@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormRequestTests {
    @Test func startsInNew() throws {
        let item = Consent.newTieredConsentFormRequest("code-9", label: "label-632")
        #expect(item.status == Consent.TieredConsentFormRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newTieredConsentFormRequest("code-9", label: "label-632")
        try item.moveTo(Consent.TieredConsentFormRequestStatus.queued)
        #expect(item.status == Consent.TieredConsentFormRequestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newTieredConsentFormRequest("code-9", label: "label-632")
        item.status = Consent.TieredConsentFormRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredConsentFormRequestStatus.new) }
    }
}
