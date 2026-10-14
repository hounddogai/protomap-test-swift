@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffAdjustmentStore = ClinicalOps.newMemoryHandoffAdjustmentStore()
        let item = ClinicalOps.newHandoffAdjustment("code-512", title: "title-556")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
