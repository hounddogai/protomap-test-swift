@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingForecastStore = ClinicalOps.newMemoryRoundingForecastStore()
        let item = ClinicalOps.newRoundingForecast("code-621", label: "label-421")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
