@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialPreference("code-374", name: "name-680")
        #expect(item.status == Staffing.CredentialPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newCredentialPreference("code-374", name: "name-680")
        try item.moveTo(Staffing.CredentialPreferenceStatus.ready)
        #expect(item.status == Staffing.CredentialPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialPreference("code-374", name: "name-680")
        item.status = Staffing.CredentialPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialPreferenceStatus.idle) }
    }
}
