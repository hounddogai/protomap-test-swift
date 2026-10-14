@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialPreferenceTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newPendingCredentialPreference("code-664", name: "name-304")
        #expect(item.status == Staffing.PendingCredentialPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newPendingCredentialPreference("code-664", name: "name-304")
        try item.moveTo(Staffing.PendingCredentialPreferenceStatus.expired)
        #expect(item.status == Staffing.PendingCredentialPreferenceStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newPendingCredentialPreference("code-664", name: "name-304")
        item.status = Staffing.PendingCredentialPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingCredentialPreferenceStatus.requested) }
    }
}
