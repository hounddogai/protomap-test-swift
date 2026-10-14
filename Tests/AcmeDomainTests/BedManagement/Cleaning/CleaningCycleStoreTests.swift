@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningCycleStore = BedManagement.newMemoryCleaningCycleStore()
        let item = BedManagement.newCleaningCycle("code-185", name: "name-292")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
