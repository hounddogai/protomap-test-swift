@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalRoundingEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalRoundingEstimateStore = ClinicalOps.newMemorySeasonalRoundingEstimateStore()
        let item = ClinicalOps.newSeasonalRoundingEstimate("code-739", name: "name-967")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
