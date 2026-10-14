@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingIsolationPreferenceTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newRollingIsolationPreference("code-682", name: "name-611")
        #expect(item.status == BedManagement.RollingIsolationPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newRollingIsolationPreference("code-682", name: "name-611")
        try item.moveTo(BedManagement.RollingIsolationPreferenceStatus.published)
        #expect(item.status == BedManagement.RollingIsolationPreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newRollingIsolationPreference("code-682", name: "name-611")
        item.status = BedManagement.RollingIsolationPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingIsolationPreferenceStatus.created) }
    }
}
