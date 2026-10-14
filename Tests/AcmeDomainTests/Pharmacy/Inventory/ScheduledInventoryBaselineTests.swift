@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryBaselineTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newScheduledInventoryBaseline("code-611", name: "name-494")
        #expect(item.status == Pharmacy.ScheduledInventoryBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newScheduledInventoryBaseline("code-611", name: "name-494")
        try item.moveTo(Pharmacy.ScheduledInventoryBaselineStatus.queued)
        #expect(item.status == Pharmacy.ScheduledInventoryBaselineStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newScheduledInventoryBaseline("code-611", name: "name-494")
        item.status = Pharmacy.ScheduledInventoryBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledInventoryBaselineStatus.new) }
    }
}
