@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedWitnessEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedWitnessEntryStore = Consent.newMemoryWeightedWitnessEntryStore()
        let item = Consent.newWeightedWitnessEntry("code-964", name: "name-182")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
