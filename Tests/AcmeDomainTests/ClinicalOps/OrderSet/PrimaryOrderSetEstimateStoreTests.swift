@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryOrderSetEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryOrderSetEstimateStore = ClinicalOps.newMemoryPrimaryOrderSetEstimateStore()
        let item = ClinicalOps.newPrimaryOrderSetEstimate("code-991", title: "title-473")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
