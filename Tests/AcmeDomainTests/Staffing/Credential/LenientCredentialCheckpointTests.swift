@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialCheckpointTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newLenientCredentialCheckpoint("code-908", title: "title-953")
        #expect(item.status == Staffing.LenientCredentialCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newLenientCredentialCheckpoint("code-908", title: "title-953")
        try item.moveTo(Staffing.LenientCredentialCheckpointStatus.rejected)
        #expect(item.status == Staffing.LenientCredentialCheckpointStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newLenientCredentialCheckpoint("code-908", title: "title-953")
        item.status = Staffing.LenientCredentialCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientCredentialCheckpointStatus.proposed) }
    }
}
