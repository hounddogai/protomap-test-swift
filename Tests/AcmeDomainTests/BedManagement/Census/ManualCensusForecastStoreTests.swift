@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryManualCensusForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ManualCensusForecastStore = BedManagement.newMemoryManualCensusForecastStore()
        let item = BedManagement.newManualCensusForecast("code-67", name: "name-533")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
