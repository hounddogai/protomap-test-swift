@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageSummaryStore = Consent.newMemoryLanguageSummaryStore()
        let item = Consent.newLanguageSummary("code-649", title: "title-616")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
