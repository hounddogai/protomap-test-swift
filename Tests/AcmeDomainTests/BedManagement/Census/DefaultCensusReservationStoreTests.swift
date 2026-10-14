@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultCensusReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultCensusReservationStore = BedManagement.newMemoryDefaultCensusReservationStore()
        let item = BedManagement.newDefaultCensusReservation("code-107", name: "name-237")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
