@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyAlertSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyAlertSlotStore = ClinicalOps.newMemoryLegacyAlertSlotStore()
        let item = ClinicalOps.newLegacyAlertSlot("code-39", label: "label-577")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
