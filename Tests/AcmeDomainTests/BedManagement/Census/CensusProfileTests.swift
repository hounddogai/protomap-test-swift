@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusProfileTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusProfile("code-36", title: "title-382")
        #expect(item.status == BedManagement.CensusProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newCensusProfile("code-36", title: "title-382")
        try item.moveTo(BedManagement.CensusProfileStatus.running)
        #expect(item.status == BedManagement.CensusProfileStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusProfile("code-36", title: "title-382")
        item.status = BedManagement.CensusProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusProfileStatus.new) }
    }
}
