@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialPolicyTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newCredentialPolicy("code-89", title: "title-409")
        #expect(item.status == Staffing.CredentialPolicyStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newCredentialPolicy("code-89", title: "title-409")
        try item.moveTo(Staffing.CredentialPolicyStatus.retired)
        #expect(item.status == Staffing.CredentialPolicyStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newCredentialPolicy("code-89", title: "title-409")
        item.status = Staffing.CredentialPolicyStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialPolicyStatus.created) }
    }
}
