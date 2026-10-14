@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferForecastStore = BedManagement.newMemoryTransferForecastStore()
        let item = BedManagement.newTransferForecast("code-955", name: "name-384")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
