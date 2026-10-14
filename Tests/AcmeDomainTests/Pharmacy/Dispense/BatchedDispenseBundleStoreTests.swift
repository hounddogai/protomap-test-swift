@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedDispenseBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedDispenseBundleStore = Pharmacy.newMemoryBatchedDispenseBundleStore()
        let item = Pharmacy.newBatchedDispenseBundle("code-133", label: "label-786")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
