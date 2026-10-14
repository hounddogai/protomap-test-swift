@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultAgreementTests {
    @Test func startsInCreated() throws {
        let item = Labs.newRollingResultAgreement("code-775", name: "name-718")
        #expect(item.status == Labs.RollingResultAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newRollingResultAgreement("code-775", name: "name-718")
        try item.moveTo(Labs.RollingResultAgreementStatus.validated)
        #expect(item.status == Labs.RollingResultAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newRollingResultAgreement("code-775", name: "name-718")
        item.status = Labs.RollingResultAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingResultAgreementStatus.created) }
    }
}
