@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingRevocationClaimTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newPendingRevocationClaim("code-470", title: "title-261")
        #expect(item.status == Consent.PendingRevocationClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newPendingRevocationClaim("code-470", title: "title-261")
        try item.moveTo(Consent.PendingRevocationClaimStatus.inProgress)
        #expect(item.status == Consent.PendingRevocationClaimStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newPendingRevocationClaim("code-470", title: "title-261")
        item.status = Consent.PendingRevocationClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingRevocationClaimStatus.planned) }
    }
}
