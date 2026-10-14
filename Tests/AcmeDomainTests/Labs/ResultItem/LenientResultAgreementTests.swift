@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultAgreementTests {
    @Test func startsInProposed() throws {
        let item = Labs.newLenientResultAgreement("code-582", title: "title-990")
        #expect(item.status == Labs.LenientResultAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newLenientResultAgreement("code-582", title: "title-990")
        try item.moveTo(Labs.LenientResultAgreementStatus.approved)
        #expect(item.status == Labs.LenientResultAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newLenientResultAgreement("code-582", title: "title-990")
        item.status = Labs.LenientResultAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientResultAgreementStatus.proposed) }
    }
}
