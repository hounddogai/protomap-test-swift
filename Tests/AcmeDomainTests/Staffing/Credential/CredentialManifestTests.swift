@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialManifestTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCredentialManifest("code-776", name: "name-503")
        #expect(item.status == Staffing.CredentialManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newCredentialManifest("code-776", name: "name-503")
        try item.moveTo(Staffing.CredentialManifestStatus.rejected)
        #expect(item.status == Staffing.CredentialManifestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCredentialManifest("code-776", name: "name-503")
        item.status = Staffing.CredentialManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialManifestStatus.proposed) }
    }
}
