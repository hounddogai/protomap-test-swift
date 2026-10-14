@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyExceptionStore = Consent.newMemoryProxyExceptionStore()
        let item = Consent.newProxyException("code-305", label: "label-368")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
