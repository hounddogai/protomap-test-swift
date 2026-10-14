@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialCheckpointTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newStrictCredentialCheckpoint("code-197", name: "name-853")
        #expect(item.status == Staffing.StrictCredentialCheckpointStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newStrictCredentialCheckpoint("code-197", name: "name-853")
        try item.moveTo(Staffing.StrictCredentialCheckpointStatus.published)
        #expect(item.status == Staffing.StrictCredentialCheckpointStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newStrictCredentialCheckpoint("code-197", name: "name-853")
        item.status = Staffing.StrictCredentialCheckpointStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictCredentialCheckpointStatus.created) }
    }
}
