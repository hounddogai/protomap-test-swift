@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryAdaptiveRevocationEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.AdaptiveRevocationEstimateStore = Consent.newMemoryAdaptiveRevocationEstimateStore()
        let item = Consent.newAdaptiveRevocationEstimate("code-855", title: "title-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
