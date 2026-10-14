@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingAlertForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingAlertForecastStore = ClinicalOps.newMemoryRollingAlertForecastStore()
        let item = ClinicalOps.newRollingAlertForecast("code-217", label: "label-55")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
