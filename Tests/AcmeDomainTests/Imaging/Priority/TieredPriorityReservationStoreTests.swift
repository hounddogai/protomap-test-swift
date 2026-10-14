@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredPriorityReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredPriorityReservationStore = Imaging.newMemoryTieredPriorityReservationStore()
        let item = Imaging.newTieredPriorityReservation("code-825", title: "title-940")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
