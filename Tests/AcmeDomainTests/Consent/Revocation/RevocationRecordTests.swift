@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationRecordTests {
    @Test func startsInDraft() throws {
        let item = Consent.newRevocationRecord("code-847", label: "label-832")
        #expect(item.status == Consent.RevocationRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newRevocationRecord("code-847", label: "label-832")
        try item.moveTo(Consent.RevocationRecordStatus.active)
        #expect(item.status == Consent.RevocationRecordStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newRevocationRecord("code-847", label: "label-832")
        item.status = Consent.RevocationRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationRecordStatus.draft) }
    }
}
