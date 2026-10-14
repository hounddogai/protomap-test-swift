@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalCensusPreferenceTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newRegionalCensusPreference("code-499", title: "title-743")
        #expect(item.status == BedManagement.RegionalCensusPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newRegionalCensusPreference("code-499", title: "title-743")
        try item.moveTo(BedManagement.RegionalCensusPreferenceStatus.reopened)
        #expect(item.status == BedManagement.RegionalCensusPreferenceStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newRegionalCensusPreference("code-499", title: "title-743")
        item.status = BedManagement.RegionalCensusPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalCensusPreferenceStatus.`open`) }
    }
}
