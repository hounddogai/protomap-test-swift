@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetSnapshotStore = ClinicalOps.newMemoryOrderSetSnapshotStore()
        let item = ClinicalOps.newOrderSetSnapshot("code-165", name: "name-728")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
