@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientOrderSetSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientOrderSetSnapshotStore = ClinicalOps.newMemoryLenientOrderSetSnapshotStore()
        let item = ClinicalOps.newLenientOrderSetSnapshot("code-677", label: "label-423")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
