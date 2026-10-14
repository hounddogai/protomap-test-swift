@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetSegmentStore = ClinicalOps.newMemoryOrderSetSegmentStore()
        let item = ClinicalOps.newOrderSetSegment("code-449", title: "title-500")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
