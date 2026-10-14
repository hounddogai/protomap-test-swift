@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardCycleTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newStrictBedBoardCycle("code-68", name: "name-324")
        #expect(item.status == BedManagement.StrictBedBoardCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newStrictBedBoardCycle("code-68", name: "name-324")
        try item.moveTo(BedManagement.StrictBedBoardCycleStatus.done)
        #expect(item.status == BedManagement.StrictBedBoardCycleStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newStrictBedBoardCycle("code-68", name: "name-324")
        item.status = BedManagement.StrictBedBoardCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictBedBoardCycleStatus.new) }
    }
}
