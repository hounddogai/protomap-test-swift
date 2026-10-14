@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryScheduleTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInventorySchedule("code-91", label: "label-479")
        #expect(item.status == Pharmacy.InventoryScheduleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newInventorySchedule("code-91", label: "label-479")
        try item.moveTo(Pharmacy.InventoryScheduleStatus.pending)
        #expect(item.status == Pharmacy.InventoryScheduleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInventorySchedule("code-91", label: "label-479")
        item.status = Pharmacy.InventoryScheduleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryScheduleStatus.draft) }
    }
}
