@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramAgreementTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newProgramAgreement("code-281", label: "label-169")
        #expect(item.status == CareManagement.ProgramAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = CareManagement.newProgramAgreement("code-281", label: "label-169")
        try item.moveTo(CareManagement.ProgramAgreementStatus.retired)
        #expect(item.status == CareManagement.ProgramAgreementStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newProgramAgreement("code-281", label: "label-169")
        item.status = CareManagement.ProgramAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramAgreementStatus.created) }
    }
}
