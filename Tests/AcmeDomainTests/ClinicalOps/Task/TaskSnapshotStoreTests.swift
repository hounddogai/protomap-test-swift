@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskSnapshotStore = ClinicalOps.newMemoryTaskSnapshotStore()
        let item = ClinicalOps.newTaskSnapshot("code-550", label: "label-509")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
