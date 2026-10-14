@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyDispenseEntryTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newLegacyDispenseEntry("code-401", label: "label-68")
        #expect(item.status == Pharmacy.LegacyDispenseEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newLegacyDispenseEntry("code-401", label: "label-68")
        try item.moveTo(Pharmacy.LegacyDispenseEntryStatus.expired)
        #expect(item.status == Pharmacy.LegacyDispenseEntryStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newLegacyDispenseEntry("code-401", label: "label-68")
        item.status = Pharmacy.LegacyDispenseEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyDispenseEntryStatus.requested) }
    }
}
