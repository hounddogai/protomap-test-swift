@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyBedBoardPreferenceTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newLegacyBedBoardPreference("code-573", label: "label-612")
        #expect(item.status == BedManagement.LegacyBedBoardPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newLegacyBedBoardPreference("code-573", label: "label-612")
        try item.moveTo(BedManagement.LegacyBedBoardPreferenceStatus.resolved)
        #expect(item.status == BedManagement.LegacyBedBoardPreferenceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newLegacyBedBoardPreference("code-573", label: "label-612")
        item.status = BedManagement.LegacyBedBoardPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyBedBoardPreferenceStatus.`open`) }
    }
}
