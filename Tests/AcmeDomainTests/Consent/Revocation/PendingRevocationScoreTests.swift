@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingRevocationScoreTests {
    @Test func startsInCreated() throws {
        let item = Consent.newPendingRevocationScore("code-366", label: "label-151")
        #expect(item.status == Consent.PendingRevocationScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newPendingRevocationScore("code-366", label: "label-151")
        try item.moveTo(Consent.PendingRevocationScoreStatus.published)
        #expect(item.status == Consent.PendingRevocationScoreStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newPendingRevocationScore("code-366", label: "label-151")
        item.status = Consent.PendingRevocationScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingRevocationScoreStatus.created) }
    }
}
