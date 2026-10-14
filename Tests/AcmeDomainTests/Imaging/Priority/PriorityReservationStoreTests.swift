@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityReservationStore = Imaging.newMemoryPriorityReservationStore()
        let item = Imaging.newPriorityReservation("code-789", name: "name-608")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
