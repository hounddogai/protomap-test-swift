@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedDispensePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedDispensePolicyStore = Pharmacy.newMemoryBatchedDispensePolicyStore()
        let item = Pharmacy.newBatchedDispensePolicy("code-298", title: "title-760")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
