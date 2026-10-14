@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormDigestStore = Consent.newMemoryConsentFormDigestStore()
        let item = Consent.newConsentFormDigest("code-534", name: "name-79")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
