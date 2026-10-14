@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultProxyClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultProxyClaimStore = Consent.newMemoryDefaultProxyClaimStore()
        let item = Consent.newDefaultProxyClaim("code-398", name: "name-611")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
