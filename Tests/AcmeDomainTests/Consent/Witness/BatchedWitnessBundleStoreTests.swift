@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedWitnessBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedWitnessBundleStore = Consent.newMemoryBatchedWitnessBundleStore()
        let item = Consent.newBatchedWitnessBundle("code-349", name: "name-818")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
