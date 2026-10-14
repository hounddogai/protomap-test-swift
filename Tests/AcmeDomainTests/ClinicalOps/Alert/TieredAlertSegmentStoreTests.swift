@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredAlertSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredAlertSegmentStore = ClinicalOps.newMemoryTieredAlertSegmentStore()
        let item = ClinicalOps.newTieredAlertSegment("code-896", label: "label-406")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
