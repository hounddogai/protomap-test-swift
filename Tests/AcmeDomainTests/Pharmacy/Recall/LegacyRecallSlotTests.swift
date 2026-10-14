@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallSlotTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLegacyRecallSlot("code-187", name: "name-147")
        #expect(item.status == Pharmacy.LegacyRecallSlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newLegacyRecallSlot("code-187", name: "name-147")
        try item.moveTo(Pharmacy.LegacyRecallSlotStatus.completed)
        #expect(item.status == Pharmacy.LegacyRecallSlotStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLegacyRecallSlot("code-187", name: "name-147")
        item.status = Pharmacy.LegacyRecallSlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyRecallSlotStatus.planned) }
    }
}
