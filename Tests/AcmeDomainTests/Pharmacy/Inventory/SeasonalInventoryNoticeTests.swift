@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryNoticeTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newSeasonalInventoryNotice("code-568", title: "title-990")
        #expect(item.status == Pharmacy.SeasonalInventoryNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newSeasonalInventoryNotice("code-568", title: "title-990")
        try item.moveTo(Pharmacy.SeasonalInventoryNoticeStatus.withdrawn)
        #expect(item.status == Pharmacy.SeasonalInventoryNoticeStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newSeasonalInventoryNotice("code-568", title: "title-990")
        item.status = Pharmacy.SeasonalInventoryNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalInventoryNoticeStatus.proposed) }
    }
}
