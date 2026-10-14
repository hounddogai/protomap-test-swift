@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryScheduledDispenseReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ScheduledDispenseReservationStore = Pharmacy.newMemoryScheduledDispenseReservationStore()
        let item = Pharmacy.newScheduledDispenseReservation("code-153", name: "name-549")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
