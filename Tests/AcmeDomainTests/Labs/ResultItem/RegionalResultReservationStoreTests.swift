@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalResultReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalResultReservationStore = Labs.newMemoryRegionalResultReservationStore()
        let item = Labs.newRegionalResultReservation("code-649", label: "label-356")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
