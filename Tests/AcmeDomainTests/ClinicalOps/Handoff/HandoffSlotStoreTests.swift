@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffSlotStore = ClinicalOps.newMemoryHandoffSlotStore()
        let item = ClinicalOps.newHandoffSlot("code-809", name: "name-361")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
