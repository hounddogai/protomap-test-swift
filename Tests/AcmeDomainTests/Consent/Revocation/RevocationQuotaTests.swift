@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationQuotaTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRevocationQuota("code-429", label: "label-796")
        #expect(item.status == Consent.RevocationQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newRevocationQuota("code-429", label: "label-796")
        try item.moveTo(Consent.RevocationQuotaStatus.inProgress)
        #expect(item.status == Consent.RevocationQuotaStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRevocationQuota("code-429", label: "label-796")
        item.status = Consent.RevocationQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationQuotaStatus.planned) }
    }
}
