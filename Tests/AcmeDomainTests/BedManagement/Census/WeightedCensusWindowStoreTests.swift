@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryWeightedCensusWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.WeightedCensusWindowStore = BedManagement.newMemoryWeightedCensusWindowStore()
        let item = BedManagement.newWeightedCensusWindow("code-716", name: "name-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
