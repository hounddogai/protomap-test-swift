@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientConsentFormBatchTests {
    @Test func startsInNew() throws {
        let item = Consent.newLenientConsentFormBatch("code-467", title: "title-249")
        #expect(item.status == Consent.LenientConsentFormBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newLenientConsentFormBatch("code-467", title: "title-249")
        try item.moveTo(Consent.LenientConsentFormBatchStatus.done)
        #expect(item.status == Consent.LenientConsentFormBatchStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLenientConsentFormBatch("code-467", title: "title-249")
        item.status = Consent.LenientConsentFormBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientConsentFormBatchStatus.new) }
    }
}
