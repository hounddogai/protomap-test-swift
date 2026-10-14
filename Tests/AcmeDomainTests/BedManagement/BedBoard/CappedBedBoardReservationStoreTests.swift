@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedBedBoardReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedBedBoardReservationStore = BedManagement.newMemoryCappedBedBoardReservationStore()
        let item = BedManagement.newCappedBedBoardReservation("code-309", name: "name-579")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
