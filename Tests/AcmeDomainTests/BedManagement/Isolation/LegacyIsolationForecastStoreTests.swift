@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyIsolationForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyIsolationForecastStore = BedManagement.newMemoryLegacyIsolationForecastStore()
        let item = BedManagement.newLegacyIsolationForecast("code-867", name: "name-22")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
