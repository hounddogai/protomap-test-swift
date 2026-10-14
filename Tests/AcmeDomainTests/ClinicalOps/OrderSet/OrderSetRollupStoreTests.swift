@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetRollupStore = ClinicalOps.newMemoryOrderSetRollupStore()
        let item = ClinicalOps.newOrderSetRollup("code-516", title: "title-387")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
