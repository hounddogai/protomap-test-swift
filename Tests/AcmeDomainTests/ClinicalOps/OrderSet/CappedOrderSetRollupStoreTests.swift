@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedOrderSetRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedOrderSetRollupStore = ClinicalOps.newMemoryCappedOrderSetRollupStore()
        let item = ClinicalOps.newCappedOrderSetRollup("code-100", label: "label-410")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
