@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryInventoryOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryInventoryOverrideStore = Pharmacy.newMemoryPrimaryInventoryOverrideStore()
        let item = Pharmacy.newPrimaryInventoryOverride("code-786", title: "title-999")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
