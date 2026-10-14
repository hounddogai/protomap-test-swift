@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryCycleStore = Pharmacy.newMemoryInventoryCycleStore()
        let item = Pharmacy.newInventoryCycle("code-949", title: "title-397")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
