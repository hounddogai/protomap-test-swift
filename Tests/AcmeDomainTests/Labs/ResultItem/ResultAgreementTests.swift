@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultAgreementTests {
    @Test func startsInDraft() throws {
        let item = Labs.newResultAgreement("code-493", title: "title-823")
        #expect(item.status == Labs.ResultAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newResultAgreement("code-493", title: "title-823")
        try item.moveTo(Labs.ResultAgreementStatus.pending)
        #expect(item.status == Labs.ResultAgreementStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newResultAgreement("code-493", title: "title-823")
        item.status = Labs.ResultAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultAgreementStatus.draft) }
    }
}
