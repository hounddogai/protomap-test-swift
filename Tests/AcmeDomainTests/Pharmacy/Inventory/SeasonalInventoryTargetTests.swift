@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryTargetTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newSeasonalInventoryTarget("code-913", title: "title-133")
        #expect(item.status == Pharmacy.SeasonalInventoryTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newSeasonalInventoryTarget("code-913", title: "title-133")
        try item.moveTo(Pharmacy.SeasonalInventoryTargetStatus.granted)
        #expect(item.status == Pharmacy.SeasonalInventoryTargetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newSeasonalInventoryTarget("code-913", title: "title-133")
        item.status = Pharmacy.SeasonalInventoryTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalInventoryTargetStatus.requested) }
    }
}
