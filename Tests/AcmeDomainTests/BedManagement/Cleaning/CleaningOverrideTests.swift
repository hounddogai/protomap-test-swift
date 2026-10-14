@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningOverrideTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCleaningOverride("code-889", label: "label-422")
        #expect(item.status == BedManagement.CleaningOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newCleaningOverride("code-889", label: "label-422")
        try item.moveTo(BedManagement.CleaningOverrideStatus.reopened)
        #expect(item.status == BedManagement.CleaningOverrideStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCleaningOverride("code-889", label: "label-422")
        item.status = BedManagement.CleaningOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningOverrideStatus.`open`) }
    }
}
