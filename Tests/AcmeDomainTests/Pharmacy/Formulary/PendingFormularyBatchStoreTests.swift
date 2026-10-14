@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingFormularyBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingFormularyBatchStore = Pharmacy.newMemoryPendingFormularyBatchStore()
        let item = Pharmacy.newPendingFormularyBatch("code-153", label: "label-158")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
