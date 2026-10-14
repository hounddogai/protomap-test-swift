@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedLanguageThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedLanguageThresholdStore = Consent.newMemoryWeightedLanguageThresholdStore()
        let item = Consent.newWeightedLanguageThreshold("code-36", name: "name-697")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
