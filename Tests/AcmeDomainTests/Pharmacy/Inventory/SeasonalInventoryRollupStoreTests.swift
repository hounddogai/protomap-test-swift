@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalInventoryRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalInventoryRollupStore = Pharmacy.newMemorySeasonalInventoryRollupStore()
        let item = Pharmacy.newSeasonalInventoryRollup("code-406", title: "title-678")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
