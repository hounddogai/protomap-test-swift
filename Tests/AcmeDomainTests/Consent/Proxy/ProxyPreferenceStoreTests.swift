@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyPreferenceStore = Consent.newMemoryProxyPreferenceStore()
        let item = Consent.newProxyPreference("code-336", title: "title-324")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
