@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedDisclosureCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedDisclosureCycleStore = Consent.newMemoryBatchedDisclosureCycleStore()
        let item = Consent.newBatchedDisclosureCycle("code-416", name: "name-318")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
