@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialCheckpointTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newCredentialCheckpoint("code-324", name: "name-511")
        #expect(item.status == Staffing.CredentialCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newCredentialCheckpoint("code-324", name: "name-511")
        try item.moveTo(Staffing.CredentialCheckpointStatus.expired)
        #expect(item.status == Staffing.CredentialCheckpointStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newCredentialCheckpoint("code-324", name: "name-511")
        item.status = Staffing.CredentialCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialCheckpointStatus.requested) }
    }
}
