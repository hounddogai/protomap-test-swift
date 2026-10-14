@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedProxyOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedProxyOverrideStore = Consent.newMemoryBatchedProxyOverrideStore()
        let item = Consent.newBatchedProxyOverride("code-993", label: "label-67")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
