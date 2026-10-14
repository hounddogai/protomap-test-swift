@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultRoundingSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultRoundingSlotStore = ClinicalOps.newMemoryDefaultRoundingSlotStore()
        let item = ClinicalOps.newDefaultRoundingSlot("code-417", title: "title-934")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
