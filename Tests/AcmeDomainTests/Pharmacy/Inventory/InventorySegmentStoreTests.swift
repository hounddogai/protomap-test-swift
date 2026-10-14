@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventorySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventorySegmentStore = Pharmacy.newMemoryInventorySegmentStore()
        let item = Pharmacy.newInventorySegment("code-238", name: "name-696")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
