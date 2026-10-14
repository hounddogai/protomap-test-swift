@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormQuotaStore = Consent.newMemoryConsentFormQuotaStore()
        let item = Consent.newConsentFormQuota("code-26", title: "title-579")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
