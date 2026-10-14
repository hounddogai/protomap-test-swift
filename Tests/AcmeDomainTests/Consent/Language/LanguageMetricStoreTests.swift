@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageMetricStore = Consent.newMemoryLanguageMetricStore()
        let item = Consent.newLanguageMetric("code-347", name: "name-345")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
