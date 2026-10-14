@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetAllocationStore = ClinicalOps.newMemoryOrderSetAllocationStore()
        let item = ClinicalOps.newOrderSetAllocation("code-893", label: "label-530")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
