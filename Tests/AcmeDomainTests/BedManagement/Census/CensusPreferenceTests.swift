@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPreferenceTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusPreference("code-556", title: "title-277")
        #expect(item.status == BedManagement.CensusPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newCensusPreference("code-556", title: "title-277")
        try item.moveTo(BedManagement.CensusPreferenceStatus.warming)
        #expect(item.status == BedManagement.CensusPreferenceStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusPreference("code-556", title: "title-277")
        item.status = BedManagement.CensusPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusPreferenceStatus.idle) }
    }
}
