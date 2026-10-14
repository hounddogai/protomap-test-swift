@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedProxyThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedProxyThresholdStore = Consent.newMemoryBatchedProxyThresholdStore()
        let item = Consent.newBatchedProxyThreshold("code-414", label: "label-266")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
