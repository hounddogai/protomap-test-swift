@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryRoundingSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryRoundingSlotStore = ClinicalOps.newMemoryPrimaryRoundingSlotStore()
        let item = ClinicalOps.newPrimaryRoundingSlot("code-419", name: "name-690")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
