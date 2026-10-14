@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageQuotaStore = Consent.newMemoryLanguageQuotaStore()
        let item = Consent.newLanguageQuota("code-424", title: "title-392")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
