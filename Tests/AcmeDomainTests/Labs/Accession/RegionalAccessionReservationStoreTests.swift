@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalAccessionReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalAccessionReservationStore = Labs.newMemoryRegionalAccessionReservationStore()
        let item = Labs.newRegionalAccessionReservation("code-951", label: "label-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
