@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedWitnessQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedWitnessQuotaStore = Consent.newMemoryBatchedWitnessQuotaStore()
        let item = Consent.newBatchedWitnessQuota("code-128", name: "name-636")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
