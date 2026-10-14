@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredTaskOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredTaskOverrideStore = ClinicalOps.newMemoryTieredTaskOverrideStore()
        let item = ClinicalOps.newTieredTaskOverride("code-401", label: "label-353")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
