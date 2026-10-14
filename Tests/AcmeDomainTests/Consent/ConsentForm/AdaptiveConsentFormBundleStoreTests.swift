@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryAdaptiveConsentFormBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.AdaptiveConsentFormBundleStore = Consent.newMemoryAdaptiveConsentFormBundleStore()
        let item = Consent.newAdaptiveConsentFormBundle("code-844", title: "title-457")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
