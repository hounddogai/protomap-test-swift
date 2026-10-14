@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormBatchTests {
    @Test func startsInNew() throws {
        let item = Consent.newGlobalConsentFormBatch("code-521", name: "name-541")
        #expect(item.status == Consent.GlobalConsentFormBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newGlobalConsentFormBatch("code-521", name: "name-541")
        try item.moveTo(Consent.GlobalConsentFormBatchStatus.done)
        #expect(item.status == Consent.GlobalConsentFormBatchStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newGlobalConsentFormBatch("code-521", name: "name-541")
        item.status = Consent.GlobalConsentFormBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalConsentFormBatchStatus.new) }
    }
}
