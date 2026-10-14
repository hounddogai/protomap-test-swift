@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedDispenseAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedDispenseAdjustmentStore = Pharmacy.newMemoryCappedDispenseAdjustmentStore()
        let item = Pharmacy.newCappedDispenseAdjustment("code-219", title: "title-964")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
