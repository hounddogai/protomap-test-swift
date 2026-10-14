@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedWitnessRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedWitnessRollupStore = Consent.newMemoryWeightedWitnessRollupStore()
        let item = Consent.newWeightedWitnessRollup("code-211", label: "label-1")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
