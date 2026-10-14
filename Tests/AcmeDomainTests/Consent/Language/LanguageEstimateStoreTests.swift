@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageEstimateStore = Consent.newMemoryLanguageEstimateStore()
        let item = Consent.newLanguageEstimate("code-958", title: "title-184")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
