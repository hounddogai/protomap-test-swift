@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictLanguageDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictLanguageDigestStore = Consent.newMemoryStrictLanguageDigestStore()
        let item = Consent.newStrictLanguageDigest("code-211", title: "title-888")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
