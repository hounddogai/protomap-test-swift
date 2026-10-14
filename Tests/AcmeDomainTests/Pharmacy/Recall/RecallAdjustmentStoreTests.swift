@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallAdjustmentStore = Pharmacy.newMemoryRecallAdjustmentStore()
        let item = Pharmacy.newRecallAdjustment("code-377", title: "title-431")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
