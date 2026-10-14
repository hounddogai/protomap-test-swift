@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalOrderSetRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalOrderSetRollupStore = ClinicalOps.newMemoryRegionalOrderSetRollupStore()
        let item = ClinicalOps.newRegionalOrderSetRollup("code-4", name: "name-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
