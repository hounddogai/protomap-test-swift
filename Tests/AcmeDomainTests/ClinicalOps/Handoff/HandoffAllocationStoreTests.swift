@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffAllocationStore = ClinicalOps.newMemoryHandoffAllocationStore()
        let item = ClinicalOps.newHandoffAllocation("code-388", title: "title-785")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
