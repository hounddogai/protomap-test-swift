@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalInventoryTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalInventoryTargetStore = Pharmacy.newMemorySeasonalInventoryTargetStore()
        let item = Pharmacy.newSeasonalInventoryTarget("code-913", title: "title-133")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
