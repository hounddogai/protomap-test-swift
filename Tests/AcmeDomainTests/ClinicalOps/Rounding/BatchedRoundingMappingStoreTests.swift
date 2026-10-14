@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedRoundingMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedRoundingMappingStore = ClinicalOps.newMemoryBatchedRoundingMappingStore()
        let item = ClinicalOps.newBatchedRoundingMapping("code-211", name: "name-659")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
