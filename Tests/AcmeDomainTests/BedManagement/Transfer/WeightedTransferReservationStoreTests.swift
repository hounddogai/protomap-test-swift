@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryWeightedTransferReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.WeightedTransferReservationStore = BedManagement.newMemoryWeightedTransferReservationStore()
        let item = BedManagement.newWeightedTransferReservation("code-936", title: "title-842")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
