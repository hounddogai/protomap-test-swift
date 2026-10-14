@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardSlotTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newRollingBedBoardSlot("code-435", title: "title-469")
        #expect(item.status == BedManagement.RollingBedBoardSlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newRollingBedBoardSlot("code-435", title: "title-469")
        try item.moveTo(BedManagement.RollingBedBoardSlotStatus.resolved)
        #expect(item.status == BedManagement.RollingBedBoardSlotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newRollingBedBoardSlot("code-435", title: "title-469")
        item.status = BedManagement.RollingBedBoardSlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingBedBoardSlotStatus.`open`) }
    }
}
