@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertForecastStore = ClinicalOps.newMemoryAlertForecastStore()
        let item = ClinicalOps.newAlertForecast("code-584", title: "title-622")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
