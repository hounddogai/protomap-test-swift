@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryVarianceStore = Pharmacy.newMemoryInventoryVarianceStore()
        let item = Pharmacy.newInventoryVariance("code-822", title: "title-829")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
