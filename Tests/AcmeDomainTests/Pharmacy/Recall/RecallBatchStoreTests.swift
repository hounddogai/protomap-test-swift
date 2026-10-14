@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallBatchStore = Pharmacy.newMemoryRecallBatchStore()
        let item = Pharmacy.newRecallBatch("code-244", label: "label-172")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
