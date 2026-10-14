@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedWitnessCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedWitnessCycleStore = Consent.newMemoryBatchedWitnessCycleStore()
        let item = Consent.newBatchedWitnessCycle("code-121", name: "name-334")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
