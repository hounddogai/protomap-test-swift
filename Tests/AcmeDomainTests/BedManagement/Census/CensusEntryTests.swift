@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusEntryTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCensusEntry("code-923", name: "name-856")
        #expect(item.status == BedManagement.CensusEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newCensusEntry("code-923", name: "name-856")
        try item.moveTo(BedManagement.CensusEntryStatus.expired)
        #expect(item.status == BedManagement.CensusEntryStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCensusEntry("code-923", name: "name-856")
        item.status = BedManagement.CensusEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusEntryStatus.requested) }
    }
}
