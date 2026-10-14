@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackRoundingSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackRoundingSlotStore = ClinicalOps.newMemoryFallbackRoundingSlotStore()
        let item = ClinicalOps.newFallbackRoundingSlot("code-335", name: "name-333")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
