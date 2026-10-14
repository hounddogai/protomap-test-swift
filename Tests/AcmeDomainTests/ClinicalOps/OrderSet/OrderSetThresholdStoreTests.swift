@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetThresholdStore = ClinicalOps.newMemoryOrderSetThresholdStore()
        let item = ClinicalOps.newOrderSetThreshold("code-675", title: "title-178")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
