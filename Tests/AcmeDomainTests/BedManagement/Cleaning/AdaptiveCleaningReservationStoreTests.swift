@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveCleaningReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveCleaningReservationStore = BedManagement.newMemoryAdaptiveCleaningReservationStore()
        let item = BedManagement.newAdaptiveCleaningReservation("code-677", name: "name-118")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
