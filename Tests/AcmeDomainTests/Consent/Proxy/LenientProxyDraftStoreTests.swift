@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientProxyDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientProxyDraftStore = Consent.newMemoryLenientProxyDraftStore()
        let item = Consent.newLenientProxyDraft("code-760", name: "name-678")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
