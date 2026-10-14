@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetForecastStore = ClinicalOps.newMemoryOrderSetForecastStore()
        let item = ClinicalOps.newOrderSetForecast("code-405", label: "label-213")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
