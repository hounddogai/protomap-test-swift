@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyClaimStore = Consent.newMemoryProxyClaimStore()
        let item = Consent.newProxyClaim("code-594", title: "title-282")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
