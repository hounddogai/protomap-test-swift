@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedSubstitutionDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedSubstitutionDigestStore = Pharmacy.newMemoryBatchedSubstitutionDigestStore()
        let item = Pharmacy.newBatchedSubstitutionDigest("code-767", title: "title-738")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
