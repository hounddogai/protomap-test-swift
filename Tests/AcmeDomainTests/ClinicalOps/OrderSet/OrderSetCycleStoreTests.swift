@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetCycleStore = ClinicalOps.newMemoryOrderSetCycleStore()
        let item = ClinicalOps.newOrderSetCycle("code-697", name: "name-74")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
