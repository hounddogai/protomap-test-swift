@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusSlotTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newGlobalCensusSlot("code-767", title: "title-763")
        #expect(item.status == BedManagement.GlobalCensusSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newGlobalCensusSlot("code-767", title: "title-763")
        try item.moveTo(BedManagement.GlobalCensusSlotStatus.running)
        #expect(item.status == BedManagement.GlobalCensusSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newGlobalCensusSlot("code-767", title: "title-763")
        item.status = BedManagement.GlobalCensusSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCensusSlotStatus.new) }
    }
}
