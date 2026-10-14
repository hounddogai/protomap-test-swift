@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertSlotStore = ClinicalOps.newMemoryAlertSlotStore()
        let item = ClinicalOps.newAlertSlot("code-159", title: "title-917")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
