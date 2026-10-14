@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryTieredInventoryNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.TieredInventoryNoticeStore = Pharmacy.newMemoryTieredInventoryNoticeStore()
        let item = Pharmacy.newTieredInventoryNotice("code-552", name: "name-944")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
