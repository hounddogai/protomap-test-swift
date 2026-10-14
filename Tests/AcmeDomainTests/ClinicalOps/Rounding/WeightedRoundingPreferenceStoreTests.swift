@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryWeightedRoundingPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.WeightedRoundingPreferenceStore = ClinicalOps.newMemoryWeightedRoundingPreferenceStore()
        let item = ClinicalOps.newWeightedRoundingPreference("code-818", label: "label-59")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
