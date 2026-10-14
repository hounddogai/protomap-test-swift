@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardCycleTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newBedBoardCycle("code-821", name: "name-367")
        #expect(item.status == BedManagement.BedBoardCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newBedBoardCycle("code-821", name: "name-367")
        try item.moveTo(BedManagement.BedBoardCycleStatus.published)
        #expect(item.status == BedManagement.BedBoardCycleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newBedBoardCycle("code-821", name: "name-367")
        item.status = BedManagement.BedBoardCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardCycleStatus.created) }
    }
}
