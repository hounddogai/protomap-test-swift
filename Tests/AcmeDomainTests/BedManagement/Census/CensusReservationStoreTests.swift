@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusReservationStore = BedManagement.newMemoryCensusReservationStore()
        let item = BedManagement.newCensusReservation("code-540", title: "title-391")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
