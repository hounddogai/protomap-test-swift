@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingRoundingTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingRoundingTierStore = ClinicalOps.newMemoryPendingRoundingTierStore()
        let item = ClinicalOps.newPendingRoundingTier("code-250", label: "label-77")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
