@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAgreementTests {
    @Test func startsInNew() throws {
        let item = Labs.newAccessionAgreement("code-544", title: "title-125")
        #expect(item.status == Labs.AccessionAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newAccessionAgreement("code-544", title: "title-125")
        try item.moveTo(Labs.AccessionAgreementStatus.running)
        #expect(item.status == Labs.AccessionAgreementStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAccessionAgreement("code-544", title: "title-125")
        item.status = Labs.AccessionAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionAgreementStatus.new) }
    }
}
