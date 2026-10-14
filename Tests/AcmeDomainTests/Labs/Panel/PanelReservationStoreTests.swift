@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelReservationStore = Labs.newMemoryPanelReservationStore()
        let item = Labs.newPanelReservation("code-935", title: "title-586")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
