@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryWeightedTaskOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.WeightedTaskOverrideStore = ClinicalOps.newMemoryWeightedTaskOverrideStore()
        let item = ClinicalOps.newWeightedTaskOverride("code-254", name: "name-846")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
