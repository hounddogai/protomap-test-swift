@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionAdjustmentStore = Pharmacy.newMemoryInteractionAdjustmentStore()
        let item = Pharmacy.newInteractionAdjustment("code-971", name: "name-879")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
