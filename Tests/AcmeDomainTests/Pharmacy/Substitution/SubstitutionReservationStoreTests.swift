@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionReservationStore = Pharmacy.newMemorySubstitutionReservationStore()
        let item = Pharmacy.newSubstitutionReservation("code-882", title: "title-271")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
