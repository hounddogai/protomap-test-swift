@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessQuotaTests {
    @Test func startsInDraft() throws {
        let item = Consent.newBatchedWitnessQuota("code-128", name: "name-636")
        #expect(item.status == Consent.BatchedWitnessQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newBatchedWitnessQuota("code-128", name: "name-636")
        try item.moveTo(Consent.BatchedWitnessQuotaStatus.suspended)
        #expect(item.status == Consent.BatchedWitnessQuotaStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newBatchedWitnessQuota("code-128", name: "name-636")
        item.status = Consent.BatchedWitnessQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedWitnessQuotaStatus.draft) }
    }
}
