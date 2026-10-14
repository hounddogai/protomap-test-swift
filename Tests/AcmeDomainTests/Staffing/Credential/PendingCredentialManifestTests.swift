@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialManifestTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPendingCredentialManifest("code-388", label: "label-971")
        #expect(item.status == Staffing.PendingCredentialManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newPendingCredentialManifest("code-388", label: "label-971")
        try item.moveTo(Staffing.PendingCredentialManifestStatus.rejected)
        #expect(item.status == Staffing.PendingCredentialManifestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPendingCredentialManifest("code-388", label: "label-971")
        item.status = Staffing.PendingCredentialManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingCredentialManifestStatus.proposed) }
    }
}
