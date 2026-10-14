@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientInventoryOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientInventoryOverrideStore = Pharmacy.newMemoryLenientInventoryOverrideStore()
        let item = Pharmacy.newLenientInventoryOverride("code-729", label: "label-227")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
