@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultReservationStore = Labs.newMemoryResultReservationStore()
        let item = Labs.newResultReservation("code-473", label: "label-803")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
