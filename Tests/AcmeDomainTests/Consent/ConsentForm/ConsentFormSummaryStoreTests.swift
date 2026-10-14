@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormSummaryStore = Consent.newMemoryConsentFormSummaryStore()
        let item = Consent.newConsentFormSummary("code-935", title: "title-57")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
