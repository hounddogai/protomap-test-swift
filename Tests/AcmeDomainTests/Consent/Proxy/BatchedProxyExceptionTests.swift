@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyExceptionTests {
    @Test func startsInProposed() throws {
        let item = Consent.newBatchedProxyException("code-51", title: "title-850")
        #expect(item.status == Consent.BatchedProxyExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newBatchedProxyException("code-51", title: "title-850")
        try item.moveTo(Consent.BatchedProxyExceptionStatus.approved)
        #expect(item.status == Consent.BatchedProxyExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newBatchedProxyException("code-51", title: "title-850")
        item.status = Consent.BatchedProxyExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedProxyExceptionStatus.proposed) }
    }
}
