@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyRollupStore = Consent.newMemoryProxyRollupStore()
        let item = Consent.newProxyRollup("code-552", name: "name-927")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
