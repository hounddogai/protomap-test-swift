@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseAdjustmentStore = Pharmacy.newMemoryDispenseAdjustmentStore()
        let item = Pharmacy.newDispenseAdjustment("code-434", name: "name-328")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
