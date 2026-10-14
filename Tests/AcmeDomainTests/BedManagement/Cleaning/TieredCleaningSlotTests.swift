@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningSlotTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTieredCleaningSlot("code-86", title: "title-512")
        #expect(item.status == BedManagement.TieredCleaningSlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newTieredCleaningSlot("code-86", title: "title-512")
        try item.moveTo(BedManagement.TieredCleaningSlotStatus.resolved)
        #expect(item.status == BedManagement.TieredCleaningSlotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTieredCleaningSlot("code-86", title: "title-512")
        item.status = BedManagement.TieredCleaningSlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredCleaningSlotStatus.`open`) }
    }
}
