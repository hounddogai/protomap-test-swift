@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreForecastStore = CareManagement.newMemoryRiskScoreForecastStore()
        let item = CareManagement.newRiskScoreForecast("code-158", label: "label-8")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
