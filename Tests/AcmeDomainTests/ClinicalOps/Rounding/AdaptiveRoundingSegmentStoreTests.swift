@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveRoundingSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveRoundingSegmentStore = ClinicalOps.newMemoryAdaptiveRoundingSegmentStore()
        let item = ClinicalOps.newAdaptiveRoundingSegment("code-578", name: "name-946")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
