@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialManifestTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newLegacyCredentialManifest("code-545", title: "title-612")
        #expect(item.status == Staffing.LegacyCredentialManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newLegacyCredentialManifest("code-545", title: "title-612")
        try item.moveTo(Staffing.LegacyCredentialManifestStatus.scheduled)
        #expect(item.status == Staffing.LegacyCredentialManifestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newLegacyCredentialManifest("code-545", title: "title-612")
        item.status = Staffing.LegacyCredentialManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyCredentialManifestStatus.planned) }
    }
}
