@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryAdaptiveLanguageEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.AdaptiveLanguageEstimateStore = Consent.newMemoryAdaptiveLanguageEstimateStore()
        let item = Consent.newAdaptiveLanguageEstimate("code-830", label: "label-902")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
