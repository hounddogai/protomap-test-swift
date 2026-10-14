@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardMetricStore = BedManagement.newMemoryBedBoardMetricStore()
        let item = BedManagement.newBedBoardMetric("code-633", name: "name-957")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
