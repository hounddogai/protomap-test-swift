@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictRevocationBatchTests {
    @Test func startsInDraft() throws {
        let item = Consent.newStrictRevocationBatch("code-351", label: "label-454")
        #expect(item.status == Consent.StrictRevocationBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newStrictRevocationBatch("code-351", label: "label-454")
        try item.moveTo(Consent.StrictRevocationBatchStatus.suspended)
        #expect(item.status == Consent.StrictRevocationBatchStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newStrictRevocationBatch("code-351", label: "label-454")
        item.status = Consent.StrictRevocationBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictRevocationBatchStatus.draft) }
    }
}
