@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingRoundingSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingRoundingSlotStore = ClinicalOps.newMemoryRollingRoundingSlotStore()
        let item = ClinicalOps.newRollingRoundingSlot("code-964", label: "label-98")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
