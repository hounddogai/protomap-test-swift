@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingOrderSetGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingOrderSetGroupStore = ClinicalOps.newMemoryPendingOrderSetGroupStore()
        let item = ClinicalOps.newPendingOrderSetGroup("code-106", label: "label-208")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
