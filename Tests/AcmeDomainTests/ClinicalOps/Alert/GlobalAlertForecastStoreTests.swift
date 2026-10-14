@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalAlertForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalAlertForecastStore = ClinicalOps.newMemoryGlobalAlertForecastStore()
        let item = ClinicalOps.newGlobalAlertForecast("code-130", label: "label-595")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
