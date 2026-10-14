@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningCycleTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCleaningCycle("code-185", name: "name-292")
        #expect(item.status == BedManagement.CleaningCycleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newCleaningCycle("code-185", name: "name-292")
        try item.moveTo(BedManagement.CleaningCycleStatus.completed)
        #expect(item.status == BedManagement.CleaningCycleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCleaningCycle("code-185", name: "name-292")
        item.status = BedManagement.CleaningCycleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningCycleStatus.planned) }
    }
}
