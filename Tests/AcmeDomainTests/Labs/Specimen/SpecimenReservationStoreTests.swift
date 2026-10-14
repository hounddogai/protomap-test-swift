@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenReservationStore = Labs.newMemorySpecimenReservationStore()
        let item = Labs.newSpecimenReservation("code-713", title: "title-227")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
