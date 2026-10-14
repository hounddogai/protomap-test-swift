@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultLanguageAllocationTests {
    @Test func startsInProposed() throws {
        let item = Consent.newDefaultLanguageAllocation("code-958", name: "name-71")
        #expect(item.status == Consent.DefaultLanguageAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newDefaultLanguageAllocation("code-958", name: "name-71")
        try item.moveTo(Consent.DefaultLanguageAllocationStatus.rejected)
        #expect(item.status == Consent.DefaultLanguageAllocationStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newDefaultLanguageAllocation("code-958", name: "name-71")
        item.status = Consent.DefaultLanguageAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultLanguageAllocationStatus.proposed) }
    }
}
