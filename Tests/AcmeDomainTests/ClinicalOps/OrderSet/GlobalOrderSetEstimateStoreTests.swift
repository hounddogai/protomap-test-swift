@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalOrderSetEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalOrderSetEstimateStore = ClinicalOps.newMemoryGlobalOrderSetEstimateStore()
        let item = ClinicalOps.newGlobalOrderSetEstimate("code-6", title: "title-500")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
