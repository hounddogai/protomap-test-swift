@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyWindowStore = Consent.newMemoryProxyWindowStore()
        let item = Consent.newProxyWindow("code-264", label: "label-866")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
