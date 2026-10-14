@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationDigestStore = Consent.newMemoryRevocationDigestStore()
        let item = Consent.newRevocationDigest("code-408", title: "title-938")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
