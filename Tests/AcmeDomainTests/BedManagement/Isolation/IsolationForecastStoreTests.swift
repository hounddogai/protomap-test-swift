@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationForecastStore = BedManagement.newMemoryIsolationForecastStore()
        let item = BedManagement.newIsolationForecast("code-165", name: "name-394")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
