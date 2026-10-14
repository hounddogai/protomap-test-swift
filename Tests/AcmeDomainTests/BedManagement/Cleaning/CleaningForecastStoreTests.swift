@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningForecastStore = BedManagement.newMemoryCleaningForecastStore()
        let item = BedManagement.newCleaningForecast("code-764", name: "name-569")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
