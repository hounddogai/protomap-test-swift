@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialEntryTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newPendingCredentialEntry("code-812", label: "label-661")
        #expect(item.status == Staffing.PendingCredentialEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newPendingCredentialEntry("code-812", label: "label-661")
        try item.moveTo(Staffing.PendingCredentialEntryStatus.validated)
        #expect(item.status == Staffing.PendingCredentialEntryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newPendingCredentialEntry("code-812", label: "label-661")
        item.status = Staffing.PendingCredentialEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingCredentialEntryStatus.created) }
    }
}
