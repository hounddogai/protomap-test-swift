@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingAllocationStore = ClinicalOps.newMemoryRoundingAllocationStore()
        let item = ClinicalOps.newRoundingAllocation("code-684", name: "name-302")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
