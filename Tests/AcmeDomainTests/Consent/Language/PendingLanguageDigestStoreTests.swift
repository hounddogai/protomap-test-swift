@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingLanguageDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingLanguageDigestStore = Consent.newMemoryPendingLanguageDigestStore()
        let item = Consent.newPendingLanguageDigest("code-383", name: "name-28")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
