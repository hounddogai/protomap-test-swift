@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyBatchStore = Consent.newMemoryProxyBatchStore()
        let item = Consent.newProxyBatch("code-587", label: "label-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
