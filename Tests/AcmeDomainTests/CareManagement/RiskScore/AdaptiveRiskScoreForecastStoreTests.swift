@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveRiskScoreForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveRiskScoreForecastStore = CareManagement.newMemoryAdaptiveRiskScoreForecastStore()
        let item = CareManagement.newAdaptiveRiskScoreForecast("code-273", name: "name-685")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
