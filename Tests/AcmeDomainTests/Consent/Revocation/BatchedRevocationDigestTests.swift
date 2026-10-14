@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedRevocationDigestTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newBatchedRevocationDigest("code-777", label: "label-993")
        #expect(item.status == Consent.BatchedRevocationDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newBatchedRevocationDigest("code-777", label: "label-993")
        try item.moveTo(Consent.BatchedRevocationDigestStatus.inProgress)
        #expect(item.status == Consent.BatchedRevocationDigestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newBatchedRevocationDigest("code-777", label: "label-993")
        item.status = Consent.BatchedRevocationDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedRevocationDigestStatus.planned) }
    }
}
