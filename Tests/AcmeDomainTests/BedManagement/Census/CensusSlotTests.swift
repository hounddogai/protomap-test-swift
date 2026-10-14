@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSlotTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCensusSlot("code-782", label: "label-351")
        #expect(item.status == BedManagement.CensusSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = BedManagement.newCensusSlot("code-782", label: "label-351")
        try item.moveTo(BedManagement.CensusSlotStatus.stopped)
        #expect(item.status == BedManagement.CensusSlotStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCensusSlot("code-782", label: "label-351")
        item.status = BedManagement.CensusSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusSlotStatus.idle) }
    }
}
