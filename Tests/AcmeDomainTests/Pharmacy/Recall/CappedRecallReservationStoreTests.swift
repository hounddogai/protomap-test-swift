@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedRecallReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedRecallReservationStore = Pharmacy.newMemoryCappedRecallReservationStore()
        let item = Pharmacy.newCappedRecallReservation("code-817", name: "name-698")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
