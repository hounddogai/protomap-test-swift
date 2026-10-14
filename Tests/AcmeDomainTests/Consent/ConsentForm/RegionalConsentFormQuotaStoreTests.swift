@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalConsentFormQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalConsentFormQuotaStore = Consent.newMemoryRegionalConsentFormQuotaStore()
        let item = Consent.newRegionalConsentFormQuota("code-768", title: "title-444")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
