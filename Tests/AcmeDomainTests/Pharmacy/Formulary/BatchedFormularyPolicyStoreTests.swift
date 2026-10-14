@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedFormularyPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedFormularyPolicyStore = Pharmacy.newMemoryBatchedFormularyPolicyStore()
        let item = Pharmacy.newBatchedFormularyPolicy("code-909", title: "title-707")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
