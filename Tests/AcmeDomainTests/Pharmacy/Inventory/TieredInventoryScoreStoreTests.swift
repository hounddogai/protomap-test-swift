@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryTieredInventoryScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.TieredInventoryScoreStore = Pharmacy.newMemoryTieredInventoryScoreStore()
        let item = Pharmacy.newTieredInventoryScore("code-415", title: "title-729")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
