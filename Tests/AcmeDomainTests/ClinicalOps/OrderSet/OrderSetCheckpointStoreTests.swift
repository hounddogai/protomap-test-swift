@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetCheckpointStore = ClinicalOps.newMemoryOrderSetCheckpointStore()
        let item = ClinicalOps.newOrderSetCheckpoint("code-304", title: "title-101")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
