@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffSnapshotStore = ClinicalOps.newMemoryHandoffSnapshotStore()
        let item = ClinicalOps.newHandoffSnapshot("code-338", name: "name-350")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
