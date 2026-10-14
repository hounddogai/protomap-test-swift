@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedLanguageRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedLanguageRequestStore = Consent.newMemoryWeightedLanguageRequestStore()
        let item = Consent.newWeightedLanguageRequest("code-103", title: "title-134")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
