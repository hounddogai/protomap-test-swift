@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryRollupTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newSeasonalInventoryRollup("code-406", title: "title-678")
        #expect(item.status == Pharmacy.SeasonalInventoryRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newSeasonalInventoryRollup("code-406", title: "title-678")
        try item.moveTo(Pharmacy.SeasonalInventoryRollupStatus.ready)
        #expect(item.status == Pharmacy.SeasonalInventoryRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newSeasonalInventoryRollup("code-406", title: "title-678")
        item.status = Pharmacy.SeasonalInventoryRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalInventoryRollupStatus.idle) }
    }
}
