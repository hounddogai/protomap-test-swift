@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedSubstitutionPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedSubstitutionPolicyStore = Pharmacy.newMemoryBatchedSubstitutionPolicyStore()
        let item = Pharmacy.newBatchedSubstitutionPolicy("code-38", name: "name-215")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
