@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageDigestStore = Consent.newMemoryLanguageDigestStore()
        let item = Consent.newLanguageDigest("code-389", name: "name-861")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
