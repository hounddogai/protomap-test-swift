@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusWindowTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCensusWindow("code-358", name: "name-748")
        #expect(item.status == BedManagement.CensusWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newCensusWindow("code-358", name: "name-748")
        try item.moveTo(BedManagement.CensusWindowStatus.scheduled)
        #expect(item.status == BedManagement.CensusWindowStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCensusWindow("code-358", name: "name-748")
        item.status = BedManagement.CensusWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusWindowStatus.planned) }
    }
}
