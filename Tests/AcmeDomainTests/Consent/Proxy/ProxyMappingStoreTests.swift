@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyMappingStore = Consent.newMemoryProxyMappingStore()
        let item = Consent.newProxyMapping("code-92", title: "title-752")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
