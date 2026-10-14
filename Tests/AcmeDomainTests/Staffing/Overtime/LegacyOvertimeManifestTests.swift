@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyOvertimeManifestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLegacyOvertimeManifest("code-876", name: "name-87")
        #expect(item.status == Staffing.LegacyOvertimeManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newLegacyOvertimeManifest("code-876", name: "name-87")
        try item.moveTo(Staffing.LegacyOvertimeManifestStatus.queued)
        #expect(item.status == Staffing.LegacyOvertimeManifestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLegacyOvertimeManifest("code-876", name: "name-87")
        item.status = Staffing.LegacyOvertimeManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyOvertimeManifestStatus.new) }
    }
}
