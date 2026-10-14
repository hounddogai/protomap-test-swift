@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyTierStore = Consent.newMemoryProxyTierStore()
        let item = Consent.newProxyTier("code-981", name: "name-262")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
