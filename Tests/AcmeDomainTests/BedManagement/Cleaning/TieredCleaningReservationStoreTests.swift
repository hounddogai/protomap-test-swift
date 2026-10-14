@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTieredCleaningReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TieredCleaningReservationStore = BedManagement.newMemoryTieredCleaningReservationStore()
        let item = BedManagement.newTieredCleaningReservation("code-480", name: "name-845")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
