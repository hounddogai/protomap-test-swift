@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyDraftStore = Consent.newMemoryProxyDraftStore()
        let item = Consent.newProxyDraft("code-696", name: "name-577")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
