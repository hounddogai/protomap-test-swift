@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultSpecimenReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultSpecimenReservationStore = Labs.newMemoryDefaultSpecimenReservationStore()
        let item = Labs.newDefaultSpecimenReservation("code-395", label: "label-367")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
