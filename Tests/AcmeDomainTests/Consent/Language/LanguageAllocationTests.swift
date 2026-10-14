@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAllocationTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageAllocation("code-397", name: "name-615")
        #expect(item.status == Consent.LanguageAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newLanguageAllocation("code-397", name: "name-615")
        try item.moveTo(Consent.LanguageAllocationStatus.approved)
        #expect(item.status == Consent.LanguageAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageAllocation("code-397", name: "name-615")
        item.status = Consent.LanguageAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageAllocationStatus.proposed) }
    }
}
