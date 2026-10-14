@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormBundleStore = Consent.newMemoryConsentFormBundleStore()
        let item = Consent.newConsentFormBundle("code-116", name: "name-445")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
