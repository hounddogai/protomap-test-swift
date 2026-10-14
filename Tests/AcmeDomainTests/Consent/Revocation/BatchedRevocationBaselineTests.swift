@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedRevocationBaselineTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newBatchedRevocationBaseline("code-228", title: "title-750")
        #expect(item.status == Consent.BatchedRevocationBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newBatchedRevocationBaseline("code-228", title: "title-750")
        try item.moveTo(Consent.BatchedRevocationBaselineStatus.cancelled)
        #expect(item.status == Consent.BatchedRevocationBaselineStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newBatchedRevocationBaseline("code-228", title: "title-750")
        item.status = Consent.BatchedRevocationBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedRevocationBaselineStatus.planned) }
    }
}
