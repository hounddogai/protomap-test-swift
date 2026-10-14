@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryWindowStore = Pharmacy.newMemoryInventoryWindowStore()
        let item = Pharmacy.newInventoryWindow("code-519", title: "title-485")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
