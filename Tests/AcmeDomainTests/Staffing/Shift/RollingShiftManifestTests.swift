@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftManifestTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newRollingShiftManifest("code-511", name: "name-611")
        #expect(item.status == Staffing.RollingShiftManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newRollingShiftManifest("code-511", name: "name-611")
        try item.moveTo(Staffing.RollingShiftManifestStatus.inReview)
        #expect(item.status == Staffing.RollingShiftManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newRollingShiftManifest("code-511", name: "name-611")
        item.status = Staffing.RollingShiftManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingShiftManifestStatus.`open`) }
    }
}
