@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredOrderSetCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredOrderSetCycleStore = ClinicalOps.newMemoryTieredOrderSetCycleStore()
        let item = ClinicalOps.newTieredOrderSetCycle("code-304", label: "label-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
