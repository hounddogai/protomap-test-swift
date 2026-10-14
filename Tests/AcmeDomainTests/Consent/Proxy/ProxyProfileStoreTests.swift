@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyProfileStore = Consent.newMemoryProxyProfileStore()
        let item = Consent.newProxyProfile("code-28", title: "title-168")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
