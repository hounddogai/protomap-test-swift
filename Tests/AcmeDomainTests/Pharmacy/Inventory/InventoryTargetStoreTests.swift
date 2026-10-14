@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryTargetStore = Pharmacy.newMemoryInventoryTargetStore()
        let item = Pharmacy.newInventoryTarget("code-762", name: "name-344")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
