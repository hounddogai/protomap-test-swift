@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyOverrideStore = Consent.newMemoryProxyOverrideStore()
        let item = Consent.newProxyOverride("code-282", name: "name-145")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
