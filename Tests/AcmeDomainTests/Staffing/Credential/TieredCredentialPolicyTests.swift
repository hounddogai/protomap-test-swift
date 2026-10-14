@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredCredentialPolicyTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newTieredCredentialPolicy("code-433", name: "name-695")
        #expect(item.status == Staffing.TieredCredentialPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newTieredCredentialPolicy("code-433", name: "name-695")
        try item.moveTo(Staffing.TieredCredentialPolicyStatus.granted)
        #expect(item.status == Staffing.TieredCredentialPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newTieredCredentialPolicy("code-433", name: "name-695")
        item.status = Staffing.TieredCredentialPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredCredentialPolicyStatus.requested) }
    }
}
