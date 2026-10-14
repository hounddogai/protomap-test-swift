@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalTaskThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalTaskThresholdStore = ClinicalOps.newMemorySeasonalTaskThresholdStore()
        let item = ClinicalOps.newSeasonalTaskThreshold("code-38", name: "name-331")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
