@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientSpecimenReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientSpecimenReservationStore = Labs.newMemoryLenientSpecimenReservationStore()
        let item = Labs.newLenientSpecimenReservation("code-772", label: "label-630")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
