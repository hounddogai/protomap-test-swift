@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRecordTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCredentialRecord("code-900", label: "label-637")
        #expect(item.status == Staffing.CredentialRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newCredentialRecord("code-900", label: "label-637")
        try item.moveTo(Staffing.CredentialRecordStatus.withdrawn)
        #expect(item.status == Staffing.CredentialRecordStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCredentialRecord("code-900", label: "label-637")
        item.status = Staffing.CredentialRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialRecordStatus.proposed) }
    }
}
