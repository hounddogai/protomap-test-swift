@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolManifestTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newGlobalFloatPoolManifest("code-765", title: "title-494")
        #expect(item.status == Staffing.GlobalFloatPoolManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newGlobalFloatPoolManifest("code-765", title: "title-494")
        try item.moveTo(Staffing.GlobalFloatPoolManifestStatus.revoked)
        #expect(item.status == Staffing.GlobalFloatPoolManifestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newGlobalFloatPoolManifest("code-765", title: "title-494")
        item.status = Staffing.GlobalFloatPoolManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalFloatPoolManifestStatus.requested) }
    }
}
