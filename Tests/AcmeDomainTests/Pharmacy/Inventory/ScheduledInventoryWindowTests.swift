@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryWindowTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newScheduledInventoryWindow("code-144", label: "label-343")
        #expect(item.status == Pharmacy.ScheduledInventoryWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newScheduledInventoryWindow("code-144", label: "label-343")
        try item.moveTo(Pharmacy.ScheduledInventoryWindowStatus.done)
        #expect(item.status == Pharmacy.ScheduledInventoryWindowStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newScheduledInventoryWindow("code-144", label: "label-343")
        item.status = Pharmacy.ScheduledInventoryWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledInventoryWindowStatus.new) }
    }
}
