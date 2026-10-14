@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalCleaningManifestTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newSeasonalCleaningManifest("code-229", name: "name-788")
        #expect(item.status == BedManagement.SeasonalCleaningManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newSeasonalCleaningManifest("code-229", name: "name-788")
        try item.moveTo(BedManagement.SeasonalCleaningManifestStatus.scheduled)
        #expect(item.status == BedManagement.SeasonalCleaningManifestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newSeasonalCleaningManifest("code-229", name: "name-788")
        item.status = BedManagement.SeasonalCleaningManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.SeasonalCleaningManifestStatus.planned) }
    }
}
