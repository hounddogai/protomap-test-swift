@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalTaskEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalTaskEstimateStore = ClinicalOps.newMemorySeasonalTaskEstimateStore()
        let item = ClinicalOps.newSeasonalTaskEstimate("code-212", label: "label-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
