@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedProxySummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedProxySummaryStore = Consent.newMemoryWeightedProxySummaryStore()
        let item = Consent.newWeightedProxySummary("code-103", name: "name-638")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
